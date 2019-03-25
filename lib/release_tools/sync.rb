# frozen_string_literal: true

module ReleaseTools
  class Sync
    attr_reader :remotes

    def initialize(remotes)
      @remotes = remotes
    end

    def execute(branch = 'master')
      sync(branch)
    end

    private

    def sync(branch)
      repository = RemoteRepository.get(
        remotes,
        global_depth: 200,
        branch: branch
      )

      repository.pull_from_all_remotes(branch)

      merge_result = repository.merge("dev/#{branch}", branch, no_ff: true)

      if merge_result.status.success?
        repository.push_to_all_remotes(branch)
      else
        warn 'Bad merge'
        warn merge_result.output
      end
    end
  end
end
