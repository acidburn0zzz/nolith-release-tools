# frozen_string_literal: true

module ReleaseTools
  module BranchCreation
    def client
      ReleaseTools::GitlabClient
    end

    def ignoring_duplicates(&block)
      yield
    rescue Gitlab::Error::Conflict, Gitlab::Error::BadRequest => ex
      if ex.message.match?('already exists')
        # no-op for idempotency
      else
        raise
      end
    end

    def create_branch_from_ref(project, branch, ref)
      $stdout.puts "Creating `#{branch}` from `#{ref}` on `#{project.path}`"

      return if dry_run?

      ignoring_duplicates do
        client.create_branch(branch, ref, project)
      end
    end
  end
end
