# frozen_string_literal: true

module ReleaseTools
  module Qa
    class SecurityIssue < Qa::Issue
      def confidential?
        true
      end

      def title
        "#{version} Security QA Issue"
      end

      def labels
        super + ',security'
      end

      protected

      def issue_presenter
        ReleaseTools::Qa::Presenters::SecurityIssuePresenter
          .new(merge_requests, self, version)
      end
    end
  end
end
