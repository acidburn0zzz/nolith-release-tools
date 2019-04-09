# frozen_string_literal: true

module ReleaseTools
  module Services
    class AutoDeployBranchService
      include BranchCreation
      PIPELINE_ID_PADDING = 7

      def initialize(pipeline_id)
        @pipeline_id = pipeline_id.to_s.rjust(PIPELINE_ID_PADDING, '0')
      end

      def create_auto_deploy_branches!
        # Find passing commits before creating branches
        ref_deployer = latest_successful_ref(Project::Deployer, gitlab_ops_client)
        ref_ee = latest_successful_ref(Project::GitlabEe)
        ref_omnibus = latest_successful_ref(Project::OmnibusGitlab)

        # Deployer uses ops.gitlab.net as the source for all branches
        create_branch_from_ref(Project::Deployer, branch_name, ref_deployer, gitlab_ops_client)
        create_branch_from_ref(Project::GitlabEe, branch_name, ref_ee)
        create_branch_from_ref(Project::OmnibusGitlab, branch_name, ref_omnibus)
      end

      private

      def version
        @version ||= gitlab_client.current_milestone.title.tr('.', '-')
      end

      def branch_name
        "#{version}-auto-deploy-#{@pipeline_id}-ee"
      end
    end
  end
end
