require_relative '../remotes'
require_relative 'base_release'
require_relative 'omnibus_gitlab_release'

module Release
  class GitlabCeRelease < BaseRelease
    private

    def remotes
      Remotes.ce_remotes
    end

    def after_execute_hook
      Release::OmnibusGitLabRelease.new(version,
                                  gitlab_repo_path: repository.path).execute
    end
  end
end
