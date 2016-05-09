require 'colorize'
require 'fileutils'

class Repository
  class CannotCloneError < StandardError; end
  class CannotCheckoutBranchError < StandardError; end
  class CannotCreateTagError < StandardError; end

  class CanonicalRemote < Struct.new(:name, :url); end

  def self.get(remotes, repository_name = nil)
    repository_name ||= remotes.values.first.split('/').last.sub(/\.git\Z/, '')

    Repository.new(File.join('/tmp', repository_name), remotes)
  end

  attr_reader :path, :remotes, :canonical_remote

  def initialize(path, remotes)
    puts 'Pushes will be ignored because of TEST env'.colorize(:yellow) if ENV['TEST']
    @path = path
    cleanup
    self.remotes = remotes
  end

  def ensure_branch_exists(branch, remote = canonical_remote.name)
    fetch_branch(branch, remote)

    checkout_branch(branch) || checkout_new_branch(branch, remote)
  end

  def create_tag(tag)
    message = "Version #{tag}"
    unless run_git %W(tag -a #{tag} -m #{message})
      raise CannotCreateTagError.new(tag)
    end

    tag
  end

  def write_file(file, content)
    in_path { File.write(file, content) }
  end

  def commit(file, message)
    run_git %W(add #{file})
    run_git %W(commit -m #{message})
  end

  def pull_from_all_remotes(ref)
    remotes.each do |remote_name, _|
      pull(remote_name, ref)
    end
  end

  def push_to_all_remotes(ref)
    remotes.each do |remote_name, _|
      push(remote_name, ref)
    end
  end

  def cleanup
    puts "Removing #{path}...".colorize(:green)
    FileUtils.rm_rf(path, secure: true)
  end

  private

  def self.run_git(args)
    args.unshift('git')
    puts "[#{Time.now}] --> #{args.join(' ')}".colorize(:cyan)
    system(*args)
  end

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
    run_git %W(remote add #{name} #{url})
  end

  def remove_remote(name)
    run_git %W(remote remove #{name})
  end

  def fetch_branch(branch, remote = canonical_remote.name)
    unless run_git %W(fetch --depth=1 --quiet #{remote} #{branch}:#{branch})
      run_git %W(fetch --depth=1 --quiet #{remote} #{branch})
    end
  end

  def checkout_branch(branch)
    run_git %W(checkout #{branch})
  end

  def checkout_new_branch(branch, remote, base_branch: 'master')
    fetch_branch(base_branch, remote)
    unless run_git %W(checkout -b #{branch} #{remote}/#{base_branch})
      raise CannotCheckoutBranchError.new(branch)
    end
  end

  def pull(remote, branch)
    run_git %W(pull --depth=10 #{remote} #{branch})
  end

  def push(remote, ref)
    cmd = %W(push #{remote} #{ref}:#{ref})
    if ENV['TEST']
      puts 'The following command will not be actually run, because of TEST env:'.colorize(:yellow)
      puts "[#{Time.now}] --| git #{cmd.join(' ')}".colorize(:yellow)
      true
    else
      run_git cmd
    end
  end

  def in_path
    Dir.chdir(path) do
      yield
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

    unless self.class.run_git(%W(clone --depth=1 --quiet --origin #{canonical_remote.name} #{canonical_remote.url} #{path}))
      raise CannotCloneError.new("Failed to clone #{canonical_remote.url} to #{path}")
    end
  end
end
