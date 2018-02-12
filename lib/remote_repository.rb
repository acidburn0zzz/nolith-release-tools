require 'colorize'
require 'fileutils'

class RemoteRepository
  class CannotCloneError < StandardError; end
  class CannotCheckoutBranchError < StandardError; end
  class CannotCommitError < StandardError; end
  class CannotCreateTagError < StandardError; end
  class CannotPullError < StandardError; end

  CanonicalRemote = Struct.new(:name, :url)
  GitCommandResult = Struct.new(:output, :status)

  def self.get(remotes, repository_name = nil, global_depth: 1)
    repository_name ||= remotes
      .values
      .first
      .split('/')
      .last
      .sub(/\.git\Z/, '')

    new(File.join('/tmp', repository_name), remotes, global_depth: global_depth)
  end

  attr_reader :path, :remotes, :canonical_remote, :global_depth

  def initialize(path, remotes, global_depth: 1)
    $stdout.puts 'Pushes will be ignored because of TEST env'.colorize(:yellow) if SharedStatus.dry_run?
    @path = path
    @global_depth = global_depth

    cleanup

    # Add remotes, performing the first clone as necessary
    self.remotes = remotes
  end

  def ensure_branch_exists(branch)
    fetch(branch)

    checkout_branch(branch) || checkout_new_branch(branch)
  end

  def fetch(ref, remote: canonical_remote.name, depth: global_depth)
    base_cmd = %w[fetch --quiet]
    base_cmd << "--depth=#{depth}" if depth
    base_cmd << remote.to_s

    _, status = run_git([*base_cmd, "#{ref}:#{ref}"])
    _, status = run_git([*base_cmd, ref]) unless status.success?

    status.success?
  end

  def checkout_new_branch(branch, base: 'master')
    fetch(base)

    _, status = run_git %W[checkout --quiet -b #{branch} #{base}]

    status.success? || raise(CannotCheckoutBranchError.new(branch))
  end

  def create_tag(tag)
    message = "Version #{tag}"
    _, status = run_git %W[tag -a #{tag} -m "#{message}"]

    status.success? || raise(CannotCreateTagError.new(tag))
  end

  def write_file(file, content)
    in_path { File.write(file, content) }
  end

  def commit(files, no_edit: false, amend: false, message: nil, author: nil)
    run_git ['add', *Array(files)] if files

    cmd = %w[commit]
    cmd << '--no-edit' if no_edit
    cmd << '--amend' if amend
    cmd << %[--author="#{author}"] if author
    cmd += ['--message', %["#{message}"]] if message

    out, status = run_git(cmd)

    status.success? || raise(CannotCommitError.new(out))
  end

  def merge(upstream, into, no_ff: false)
    cmd = %w[merge --no-edit --no-log]
    cmd << '--no-ff' if no_ff
    cmd += [upstream, into]

    GitCommandResult.new(*run_git(cmd))
  end

  def status(short: false)
    cmd = %w[status]
    cmd << '--short' if short

    output, = run_git(cmd)

    output
  end

  def log(latest: false, no_merges: false, format: nil, paths: nil)
    format_pattern =
      case format
      when :author
        '%an'
      when :message
        '%B'
      end

    cmd = %w[log --author-date-order]
    cmd << '-1' if latest
    cmd << '--no-merges' if no_merges
    cmd << "--format='#{format_pattern}'" if format_pattern
    if paths
      cmd << '--'
      cmd += Array(paths)
    end

    output, = run_git(cmd)
    output&.squeeze!("\n") if format_pattern == :message

    output
  end

  def head
    output, = run_git(%w[rev-parse --verify HEAD])

    output.chomp
  end

  def pull(ref, remote: canonical_remote.name, depth: global_depth)
    cmd = %w[pull --quiet]
    cmd << "--depth=#{depth}" if depth
    cmd << remote.to_s
    cmd << ref

    _, status = run_git(cmd)

    if conflicts?
      raise CannotPullError.new("Conflicts were found when pulling #{ref} from #{remote}")
    end

    status.success?
  end

  def pull_from_all_remotes(ref, depth: global_depth)
    remotes.each do |remote_name, _|
      pull(ref, remote: remote_name, depth: depth)
    end
  end

  def push(remote, ref)
    cmd = %W[push #{remote} #{ref}:#{ref}]

    if SharedStatus.dry_run?
      $stdout.puts
      $stdout.puts 'The following command will not be actually run, because of TEST env:'.colorize(:yellow)
      $stdout.puts "[#{Time.now}] --| git #{cmd.join(' ')}".colorize(:yellow)

      true
    else
      _, status = run_git(cmd)
      status.success?
    end
  end

  def push_to_all_remotes(ref)
    remotes.each do |remote_name, _|
      push(remote_name, ref)
    end
  end

  def cleanup
    $stdout.puts "Removing #{path}...".colorize(:green) if Dir.exist?(path)
    FileUtils.rm_rf(path, secure: true)
  end

  def self.run_git(args)
    final_args = ['git', *args]
    $stdout.puts "[#{Time.now}] [#{Dir.pwd}] #{final_args.join(' ')}".colorize(:cyan)

    cmd_output = `#{final_args.join(' ')} 2>&1`

    [cmd_output, $CHILD_STATUS]
  end

  private

  # Given a Hash of remotes {name: url}, add each one to the repository
  def remotes=(new_remotes)
    @remotes = new_remotes.dup
    @canonical_remote = CanonicalRemote.new(*remotes.first)

    new_remotes.each do |remote_name, remote_url|
      # Canonical remote doesn't need to be added twice
      next if remote_name == canonical_remote.name

      add_remote(remote_name, remote_url)
    end
  end

  def add_remote(name, url)
    _, status = run_git %W[remote add #{name} #{url}]

    status.success?
  end

  def checkout_branch(branch)
    _, status = run_git %W[checkout --quiet #{branch}]

    status.success?
  end

  def in_path
    Dir.chdir(path) do
      yield
    end
  end

  def conflicts?
    in_path do
      output = `git ls-files -u`
      return !output.empty?
    end
  end

  def run_git(args)
    ensure_repo_exist
    in_path do
      self.class.run_git(args)
    end
  end

  def ensure_repo_exist
    return if File.exist?(path) && File.directory?(File.join(path, '.git'))

    cmd = %w[clone --quiet]
    cmd << "--depth=#{global_depth}" if global_depth
    cmd << '--origin' << canonical_remote.name.to_s << canonical_remote.url << path

    _, status = self.class.run_git(cmd)
    unless status.success?
      raise CannotCloneError.new("Failed to clone #{canonical_remote.url} to #{path}")
    end
  end
end
