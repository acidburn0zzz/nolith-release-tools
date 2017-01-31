require_relative 'gitlab_ce_release'

module Release
  class GitlabEeRelease < GitlabCeRelease
    private

    def remotes
      Remotes.remotes(:ee, dev_only: options[:security])
    end
  end
end
