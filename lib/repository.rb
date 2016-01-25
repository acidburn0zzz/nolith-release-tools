require 'fileutils'

class Repository
  def self.get(url, path)
    full_path = File.join('/tmp', path)

    if File.exists?(full_path)
      FileUtils.rm_r(full_path)
    end

    if system(*%W(git clone #{url} #{full_path}))
      Repository.new(full_path)
    else
      raise "Failed to clone #{url} to #{full_path}"
    end
  end

  def initialize(path)
    @path = path
  end

  def ensure_branch_exists(branch, remote)
    if checkout_branch(branch)
      true
    else
      unless create_branch(branch, remote + '/' + branch)
        create_branch(branch, remote + '/master')
      end

      checkout_branch(branch)
    end
  end


  def checkout_branch(branch)
    run %W(git checkout #{branch})
  end

  def fetch
    run %W(git fetch --all)
  end

  def pull(remotes, branch)
    remotes.each do |remote|
      run %W(git pull #{remote} #{branch})
    end
  end

  def create_tag(branch, tag = nil)
    checkout_branch(branch)

    if tag
      version = tag
    else
      version = execute { File.read('VERSION').strip }
      version.prepend("v") if version[0] != "v"
    end

    message = "Version #{version}"
    run %W(git tag -a #{version} -m #{message})
    version
  end

  def create_branch(branch, from = 'master')
    run %W(git branch #{branch} #{from})
  end

  # Given an Array of remotes, add each one to the repository, then fetch
  def add_remotes(remotes)
    remotes.each_with_index do |remote, i|
      add_remote("remote-#{i}", remote)
    end

    fetch
  end

  def add_remote(key, url)
    run %W(git remote add #{key} #{url})
  end

  def execute(branch = nil)
    Dir.chdir(@path) do
      yield
    end
  end

  def commit(file, message)
    run %W(git add #{file})
    run %W(git commit -m #{message})
  end

  def checkout_and_write(branch, file, content)
    checkout_branch(branch)
    execute { File.write(file, content) }
  end

  def push(remote, ref)
    if ENV['TEST']
      puts 'Push ignored because TEST env'.colorize(:yellow)
      true
    else
      run %W(git push #{remote} #{ref}:#{ref})
    end
  end

  private

  def run(args)
    execute do
      system(*args)
    end
  end
end
