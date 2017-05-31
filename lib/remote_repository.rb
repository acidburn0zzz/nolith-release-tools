require 'colorize'
require 'fileutils'

class RemoteRepository
  class CannotCloneError < StandardError; end
  class CannotCheckoutBranchError < StandardError; end
  class CannotCreateTagError < StandardError; end
  class CannotPullError < StandardError; end

  CanonicalRemote = Struct.new(:name, :url)

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
    stdout_puts 'Pushes will be ignored because of TEST env'.colorize(:yellow) if ENV['TEST']
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

    run_git([*base_cmd, ref]) unless run_git([*base_cmd, "#{ref}:#{ref}"])
  end

  def checkout_new_branch(branch, base_branch: 'master')
    fetch(base_branch)

    unless run_git %W[checkout --quiet -b #{branch} #{base_branch}]
      raise CannotCheckoutBranchError.new(branch)
    end
  end

  def create_tag(tag)
    message = "Version #{tag}"
    unless run_git %W[tag -a #{tag} -m #{message}]
      raise CannotCreateTagError.new(tag)
    end

    tag
  end

  def write_file(file, content)
    in_path { File.write(file, content) }
  end

  def commit(files, no_edit: false, amend: false, message: nil, author: nil)
    run_git ['add', *Array(files)] if files

    cmd = %w[commit --quiet]
    cmd << '--no-edit' if no_edit
    cmd << '--amend' if amend
    cmd << "--author=#{author}" if author
    cmd += ['--message', message] if message

    run_git cmd
  end

  def merge(upstream, into, no_ff: false)
    cmd = %w[merge --quiet --no-edit]
    cmd << '--no-ff' if no_ff
    cmd += [upstream, into]

    run_git cmd
  end

  def status(short: false)
    cmd = %w[status]
    cmd << '--short' if short

    run_git(cmd, output: true)
  end

  def log(latest: false, no_merges: false, author_name: false, message: false, files: nil)
    cmd = %w[log --date-order]
    cmd << '-1' if latest
    cmd << '--no-merges' if no_merges
    cmd << "--pretty=format:'%an'" if author_name
    cmd << "--pretty=format:'%B'" if message
    cmd << '--' << files if files

    output = run_git(cmd, output: true)
    output.squeeze!("\n") if message

    output
  end

  def head
    run_git(%w[rev-parse --verify HEAD], output: true).chomp
  end

  def pull(ref, remote: canonical_remote.name, depth: global_depth)
    cmd = %w[pull --quiet]
    cmd << "--depth=#{depth}" if depth
    cmd << remote.to_s
    cmd << ref

    run_git(cmd)

    if conflicts?
      raise CannotPullError.new("Conflicts were found when pulling #{ref} from #{remote}")
    end
  end

  def pull_from_all_remotes(ref, depth: global_depth)
    remotes.each do |remote_name, _|
      pull(ref, remote: remote_name, depth: depth)
    end
  end

  def push(remote, ref)
    cmd = %W[push #{remote} #{ref}:#{ref}]
    if ENV['TEST']
      stdout_puts
      stdout_puts 'The following command will not be actually run, because of TEST env:'.colorize(:yellow)
      stdout_puts "[#{Time.now}] --| git #{cmd.join(' ')}".colorize(:yellow)

      true
    else
      run_git cmd
    end
  end

  def push_to_all_remotes(ref)
    remotes.each do |remote_name, _|
      push(remote_name, ref)
    end
  end

  def cleanup
    stdout_puts "Removing #{path}...".colorize(:green) if Dir.exist?(path)
    FileUtils.rm_rf(path, secure: true)
  end

  def self.run_git(args, output: false)
    final_args = ['git', *args]
    stdout_puts "[#{Time.now}] --> #{final_args.join(' ')}".colorize(:cyan)

    if output
      `#{final_args.join(' ')}`
    else
      system(*final_args)
    end
  end

  def self.stdout_puts(*args)
    $stdout.puts(*args)
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
    run_git %W[remote add #{name} #{url}]
  end

  def checkout_branch(branch)
    run_git %W[checkout --quiet #{branch}]
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

  def run_git(args, output: false)
    ensure_repo_exist
    in_path do
      self.class.run_git(args, output: output)
    end
  end

  def ensure_repo_exist
    return if File.exist?(path) && File.directory?(File.join(path, '.git'))

    cmd = %w[clone --quiet]
    cmd << "--depth=#{global_depth}" if global_depth
    cmd << '--origin' << canonical_remote.name.to_s << canonical_remote.url << path

    unless self.class.run_git(cmd)
      raise CannotCloneError.new("Failed to clone #{canonical_remote.url} to #{path}")
    end
  end

  def stdout_puts(*args)
    self.class.stdout_puts(*args)
  end
end
