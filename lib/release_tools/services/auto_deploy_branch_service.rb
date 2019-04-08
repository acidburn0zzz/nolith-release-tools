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
        ref_ee = latest_successful_ref(Project::GitlabEe)
        ref_omnibus = latest_successful_ref(Project::OmnibusGitlab)

        create_branch_from_ref(Project::GitlabEe, branch_name, ref_ee)
        create_branch_from_ref(Project::OmnibusGitlab, branch_name, ref_omnibus)
      end

      private

      def version
        @version ||= client.current_milestone.title.tr('.', '-')
      end

      def branch_name
        "#{version}-auto-deploy-#{@pipeline_id}-ee"
      end

      def latest_successful_ref(project)
        ReleaseTools::Commits.new(project).latest_successful.id
      end
    end
  end
end
