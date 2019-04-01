# frozen_string_literal: true

module ReleaseTools
  module Services
    class MonthlyPreparationService
      include BranchCreation

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

        create_branch_from_ref(Project::GitlabEe, ee_branch, 'master')
        create_branch_from_ref(Project::GitlabCe, ce_branch, 'master')
        create_branch_from_ref(Project::OmnibusGitlab, ee_branch, 'master')
        create_branch_from_ref(Project::OmnibusGitlab, ce_branch, 'master')
      end
    end
  end
end
