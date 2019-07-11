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

      protected

      def template_path
        File.expand_path('../../../templates/qa.md.erb', __dir__)
      end

      def issue_presenter
        ReleaseTools::Qa::Presenters::IssuePresenter
          .new(merge_requests, self, version)
      end

      def parent_issue
        ReleaseTools::PatchIssue.new(version: version)
      end
    end
  end
end
