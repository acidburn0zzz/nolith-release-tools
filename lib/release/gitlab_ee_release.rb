require_relative 'gitlab_ce_release'

module Release
  class GitlabEeRelease < GitlabCeRelease
    private

    def remotes
      Project::GitlabEe.remotes(dev_only: options[:security])
    end
  end
end
