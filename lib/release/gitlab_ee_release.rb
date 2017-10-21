require_relative 'gitlab_ce_release'
require_relative '../project/gitlab_ee'

module Release
  class GitlabEeRelease < GitlabCeRelease
    private

    def repository
      path_to_your_local_repo = File.join('/Users/remy/Code/GitLab/gdk-ee/gitlab')
      @repository ||= RemoteRepository.new(path_to_your_local_repo, remotes, global_depth: 10)
    end

    def remotes
      Project::GitlabEe.remotes(dev_only: options[:security])
    end
  end
end
