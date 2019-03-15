# frozen_string_literal: true

module ReleaseTools
  module Services
    class MonthlyPreparationService
      def initialize(version)
        @version = version
      end

      def create_label
        $stdout.puts "Creating `#{PickIntoLabel.for(@version)}` label"

        return if dry_run?

        ignoring_duplicates do
          PickIntoLabel.create(@version)
        end
      end

      def create_stable_branches
        ce_branch = @version.stable_branch(ee: false)
        ee_branch = @version.stable_branch(ee: true)

        create_stable_branch(Project::GitlabEe, ee_branch)
        create_stable_branch(Project::GitlabCe, ce_branch)
        create_stable_branch(Project::OmnibusGitlab, ee_branch)
        create_stable_branch(Project::OmnibusGitlab, ce_branch)
      end

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

      def create_stable_branch(project, branch)
        $stdout.puts "Creating `#{branch}` on `#{project.path}`"

        return if dry_run?

        ignoring_duplicates do
          client.create_branch(branch, 'master', project)
        end
      end
    end
  end
end
