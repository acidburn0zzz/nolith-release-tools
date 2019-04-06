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
        ref_deployer = latest_successful_ref(Project::Deployer, gitlab_ops_client)
        ref_ce = latest_successful_ref(Project::GitlabCe)
        ref_ee = latest_successful_ref(Project::GitlabEe)
        ref_omnibus = latest_successful_ref(Project::OmnibusGitlab)

        # Deployer uses ops.gitlab.net as the source for all branches
        create_branch_from_ref(Project::Deployer, branch_name, ref_deployer, gitlab_ops_client)
        create_branch_from_ref(Project::GitlabCe, branch_name, ref_ce)
        create_branch_from_ref(Project::GitlabEe, branch_name, ref_ee)
        create_branch_from_ref(Project::OmnibusGitlab, branch_name, ref_omnibus)
        update_auto_deploy_ci
      end

      def filter_branches
        versions = []
        Struct.new("Version", :version, :pipeline_id, :branch_name)
        ReleaseTools::GitlabClient.branches(ReleaseTools::Project::GitlabEe.path).auto_paginate.each do |branch|
          next unless branch.name.match?(/^\d+-\d+-auto-deploy-\d+-ee$/)

          branch_name = branch.name
          version = branch.name.match(/^(\d+-\d+)-auto-deploy-(\d+)-ee$/)[1].tr('-', '.')
          pipeline_id = branch.name.match(/^(\d+-\d+)-auto-deploy-(\d+)-ee$/)[2]
          version_data = Struct::Version.new(version, pipeline_id, branch_name)
          versions << version_data
        end

        latest_version = []
        versions.each do |v|
          latest_version << v.version
        end

        latest_version.uniq!
        latest_version = VersionSorter.rsort(latest_version).first

        pipelines = []
        versions.each do |v|
          pipelines << v.pipeline_id if v.version == latest_version
        end

        branch = versions.find { |struct| struct.version == latest_version && struct.pipeline_id == pipelines.sort.reverse.first }.branch_name
        { version: latest_version, branch: branch }
      end

      private

      def update_auto_deploy_ci
        gitlab_client.update_variable(Project::ReleaseTools.path, CI_VAR_AUTO_DEPLOY, branch_name)
      rescue Gitlab::Error::NotFound
        gitlab_client.create_variable(Project::ReleaseTools.path, CI_VAR_AUTO_DEPLOY, branch_name)
      end
    end
  end
end
