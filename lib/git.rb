class Git
  def initialize(path)
    @path = path
  end

  def create_tag
    execute do
      version = File.read('VERSION').strip
      message = "Version #{version}"
      system *%W(git tag -a v#{version} -m #{message})
    end
  end

  def create_stable(branch_name)
    execute do
      system *%W(git branch #{branch_name})
    end
  end

  def add_remote(key, url)
    execute do
      system *%W(git remote add #{key} #{url})
    end
  end

  def execute
    Dir.chdir(@path) do
      system *%W(git checkout master)
      yield
    end
  end

  def commit(file, content, message)
    execute do
      File.write(file, content)
      system *%W(git add -A)
      system *%W(git commit -m #{message})
    end
  end

  def push(remote, ref)
    execute do
      system *%W(git push #{remote} #{ref}:#{ref})
    end
  end
end
