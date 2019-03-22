# frozen_string_literal: true

module ReleaseTools
  module Services
    class BranchService
      private

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

      def create_branch(project, branch, commit = 'master')
        $stdout.puts "Creating `#{branch}` on `#{project.path}` using commit #{commit}"

        return if dry_run?

        ignoring_duplicates do
          client.create_branch(branch, commit, project)
        end
      end
    end
  end
end
