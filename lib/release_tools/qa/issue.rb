# frozen_string_literal: true

module ReleaseTools
  module Qa
    class Issue < ReleaseTools::Issue
      def title
        "#{version} QA Issue"
      end

      def labels
        'QA task'
      end

      def add_comment(message)
        ReleaseTools::GitlabClient
          .create_issue_note(project, issue: remote_issuable, body: message)
      end

      def link!
        ReleaseTools::GitlabClient.link_issues(self, parent_issue)
      end

      def create?
        merge_requests.any?
      end

      def gitlab_test_instance
        # Patch releases are deployed to preprod
        # Auto-deploy releases are deployed to staging
        auto_deploy_version? ? 'https://staging.gitlab.com' : 'https://pre.gitlab.com'
      end

      protected

      def template_path
        File.expand_path('../../../templates/qa.md.erb', __dir__)
      end

      def issue_presenter
        ReleaseTools::Qa::IssuePresenter
          .new(merge_requests, self, version)
      end

      def parent_issue
        ReleaseTools::PatchIssue.new(version: version)
      end

      def auto_deploy_version?
        version =~ ReleaseTools::Qa::Ref::AUTO_DEPLOY_TAG_REGEX
      end
    end
  end
end
