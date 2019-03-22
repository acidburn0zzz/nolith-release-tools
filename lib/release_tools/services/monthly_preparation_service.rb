# frozen_string_literal: true

module ReleaseTools
  module Services
    class MonthlyPreparationService < BranchService
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

        create_branch(Project::GitlabEe, ee_branch)
        create_branch(Project::GitlabCe, ce_branch)
        create_branch(Project::OmnibusGitlab, ee_branch)
        create_branch(Project::OmnibusGitlab, ce_branch)
      end
    end
  end
end
