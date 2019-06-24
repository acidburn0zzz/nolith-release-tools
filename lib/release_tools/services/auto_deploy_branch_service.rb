# frozen_string_literal: true

module ReleaseTools
  module Services
    class AutoDeployBranchService
      include BranchCreation

      CI_VAR_AUTO_DEPLOY = 'AUTO_DEPLOY_BRANCH'

      attr_reader :branch_name

      def initialize(branch_name)
        @branch_name = branch_name
      end

      def create_branches!
        # Find passing commits before creating branches
        ref_ce = latest_successful_ref(Project::GitlabCe)
        ref_ee = latest_successful_ref(Project::GitlabEe)
        ref_omnibus = latest_successful_ref(Project::OmnibusGitlab)

        results = [
          create_branch_from_ref(Project::GitlabCe, branch_name, ref_ce),
          create_branch_from_ref(Project::GitlabEe, branch_name, ref_ee),
          create_branch_from_ref(Project::OmnibusGitlab, branch_name, ref_omnibus)
        ]

        update_auto_deploy_ci

        results
      end

      private

      def version
        @version ||= gitlab_client.current_milestone.title.tr('.', '-')
      end

      def update_auto_deploy_ci
        gitlab_client.update_variable(Project::ReleaseTools.path, CI_VAR_AUTO_DEPLOY, branch_name)
      rescue Gitlab::Error::NotFound
        gitlab_client.create_variable(Project::ReleaseTools.path, CI_VAR_AUTO_DEPLOY, branch_name)
      end
    end
  end
end
