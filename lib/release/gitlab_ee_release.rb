require_relative 'gitlab_ce_release'

module Release
  class GitlabEeRelease < GitlabCeRelease
    private

    def remotes
      Remotes.remotes(:ee, dev_only: options[:security])
    end

    def security_release_hook
      unless GitlabDevClient.fetch_variable(:ee)
        GitlabDevClient.create_variable(:ee, security_repository)
      end

      super
    end
  end
end
