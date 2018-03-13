module Project
  class BaseProject
    def self.remotes(dev_only: false)
      if dev_only
        self::REMOTES.slice(:dev)
      else
        self::REMOTES
      end
    end

    def self.path
      raise NotImplementedError
    end

    def self.group
      'gitlab-org'
    end
  end
end
