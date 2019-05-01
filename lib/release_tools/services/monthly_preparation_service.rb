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
        create_branch_from_ref(Project::CNGImage, ce_branch, 'master')
        create_branch_from_ref(Project::CNGImage, ee_branch, 'master')

        # Helm charts follow different branching scheme
        helm_repo = ReleaseTools::RemoteRepository.get(ReleaseTools::Project::HelmGitlab.remotes)
        version_manager = ReleaseTools::Helm::VersionManager.new(helm_repo)
        helm_version = version_manager.next_version(@version.to_ce)
        branch = helm_version.stable_branch(ee: false)
        create_branch_from_ref(Project::HelmGitlab, branch, 'master')
      end
    end
  end
end
