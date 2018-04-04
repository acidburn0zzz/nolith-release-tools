require_relative 'gitlab_ce_release'
require_relative '../project/gitlab_ee'

module Release
  class GitlabEeRelease < GitlabCeRelease
    private

    def remotes
      Project::GitlabEe.remotes
    end
  end
end
