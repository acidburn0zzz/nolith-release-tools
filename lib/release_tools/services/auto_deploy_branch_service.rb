# frozen_string_literal: true

module ReleaseTools
  module Services
    class AutoDeployBranchService < BranchService
      PIPELINE_ID_PADDING = 7
      def initialize(pipeline_id)
        @pipeline_id = pipeline_id.to_s.rjust(PIPELINE_ID_PADDING, '0')
        @version = client.current_milestone.title.tr('.', '-')
      end

      def create_auto_deploy_branches!
        # Find passing commits before creating branches
        commit_ee = branch_commit(Project::GitlabEe)
        commit_omnibus = branch_commit(Project::OmnibusGitlab)

        create_branch(Project::GitlabEe, branch_name, commit_ee)
        create_branch(Project::OmnibusGitlab, branch_name, commit_omnibus)
      end

      private

      def branch_name
        "#{@version}-auto-deploy-#{@pipeline_id}-ee"
      end

      def branch_commit(project)
        ReleaseTools::Commits.new(project).latest_successful.id
      end
    end
  end
end
