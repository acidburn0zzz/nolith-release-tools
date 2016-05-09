require_relative 'gitlab_ce_release'

module Release
  class GitlabEeRelease < GitlabCeRelease
    private

    def remotes
      Remotes.ee_remotes
    end
  end
end
