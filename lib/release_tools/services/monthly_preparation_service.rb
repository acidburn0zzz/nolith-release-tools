# frozen_string_literal: true

module ReleaseTools
  module Services
    class MonthlyPreparationService
      include ::SemanticLogger::Loggable
      include BranchCreation

      def initialize(version)
        @version = version
      end

      def create_label
        logger.info("Creating monthly Pick label", label: PickIntoLabel.for(@version))

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
        create_branch_from_ref(Project::OmnibusGitlab, ce_branch, 'master')
        create_branch_from_ref(Project::CNGImage, ce_branch, 'master')
        create_branch_from_ref(Project::CNGImage, ee_branch, 'master')

        # Helm charts follow different branching scheme
        create_helm_branch
      end

      def create_helm_branch
        project = ReleaseTools::Project::HelmGitlab
        repo = ReleaseTools::RemoteRepository.get(project.remotes)

        version_manager = ReleaseTools::Helm::VersionManager.new(repo)
        helm_version = version_manager.next_version(@version.to_ce)

        create_branch_from_ref(project, helm_version.stable_branch, 'master')
      ensure
        repo.cleanup
      end
    end
  end
end
