class Repository
  def self.get(url, path)
    full_path = File.join('/tmp', path)

    unless File.exists?(full_path)
      system(*%W(git clone #{url} #{full_path}))
    end

    Repository.new(full_path)
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

  def pull(remote, branch)
    run %W(git pull #{remote} #{branch})
  end

  def create_tag(branch)
    checkout_branch(branch)
    version = execute { File.read('VERSION').strip }
    message = "Version #{version}"
    run %W(git tag -a v#{version} -m #{message})
  end

  def create_branch(branch, from = 'master')
    run %W(git branch #{branch} #{from})
  end

  def add_remote(key, url)
    run %W(git remote add #{key} #{url})
  end

  def execute(branch = nil)
    Dir.chdir(@path) do
      yield
    end
  end

  def commit(file, content, message, branch)
    checkout_branch(branch)
    execute { File.write(file, content) }
    run %W(git add VERSION)
    run %W(git commit -m #{message})
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