require_relative 'release'
require_relative 'remotes'
require_relative 'omnibus_release'

class GitlabRelease < Release

  private

  def after_execute_hook
    OmnibusRelease.new(version,
                       Remotes.omnibus_gitlab_remotes,
                       gitlab_repo_path: repository.path).execute
  end

end
