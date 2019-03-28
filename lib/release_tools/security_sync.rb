# frozen_string_literal: true

module ReleaseTools
  class SecuritySync
    SECURITY_SOURCE = :dev

    def initialize(project)
      @project = project
    end

    # Sync stable branch and tag for from a security repository to all remotes
    #
    # Fetches the stable branch for the specified version from all remotes, then
    # merges the branch from the security remote and pushes the branch and tag
    # to all remotes, bringing them all back in sync after a security release.
    def execute(version)
      branch = version.stable_branch

      # NOTE: We have to use the `REMOTES` constant, as the `remotes` method
      # would only return `dev` during a security release.
      repository = RemoteRepository
        .get(@project::REMOTES, global_depth: 200, branch: branch)

      repository.pull_from_all_remotes(branch)

      merge_result = repository
        .merge("#{SECURITY_SOURCE}/#{branch}", branch, no_ff: true)

      if merge_result.status.success?
        repository.push_to_all_remotes(branch)
        repository.push_to_all_remotes(version.tag)
      else
        warn "Bad merge of `#{SECURITY_SOURCE}/#{branch}`".colorize(:red)
        warn merge_result.output.colorize(:red).indent(4)
      end
    end
  end
end
