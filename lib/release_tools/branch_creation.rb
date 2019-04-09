# frozen_string_literal: true

module ReleaseTools
  module BranchCreation
    def gitlab_client
      ReleaseTools::GitlabClient
    end

    def gitlab_ops_client
      ReleaseTools::GitlabOpsClient
    end

    def ignoring_duplicates
      yield
    rescue Gitlab::Error::Conflict, Gitlab::Error::BadRequest => ex
      if ex.message.match?('already exists')
        # no-op for idempotency
      else
        raise
      end
    end

    def create_branch_from_ref(project, branch, ref, client = gitlab_client)
      $stdout.puts "Creating `#{branch}` from `#{ref}` on `#{project.path}`"

      return if dry_run?

      ignoring_duplicates do
        client.create_branch(branch, ref, project)
      end
    end

    def latest_successful_ref(project, client = gitlab_client)
      ReleaseTools::Commits.new(project, client).latest_successful.id
    end
  end
end
