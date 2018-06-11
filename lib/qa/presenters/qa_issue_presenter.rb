require_relative '../issuable_sort_by_labels'
require_relative '../formatters/merge_requests_formatter'

module Qa
  module Presenters
    class QaIssuePresenter
      def initialize(merge_requests, remote_issue, version)
        @merge_requests = merge_requests
        @remote_issue = remote_issue
        @version = version
      end

      def present
        "".tap do |text|
          if @remote_issue
            text << @remote_issue.description
          else
            text << header_text
          end
          text << "\n#{changes_header}\n\n"
          text << formatter.lines.join("\n")
          text << automated_qa_text
        end
      end

      private

      def header_text
        <<~HEREDOC
          ## README (Remove this section after completing it's tasks)

          This issue is automatically generated to include all Merge Requests since the previous release for the purpose of a manual QA in the staging environment.

          It should be generated before moving on to staging.

          ## Tasks

          General Quality info can be found at the [Quality Handbook](https://about.gitlab.com/handbook/quality/).

          You can use the [QA Checklist](https://gitlab.com/gitlab-org/release-tools/blob/master/doc/qa-checklist.md)
          to ensure you've tested critical features.
        HEREDOC
      end

      def changes_header
        "## #{@version} Changes"
      end

      def automated_qa_text
        <<~HEREDOC
          ### #{@version} Automated QA

          Link to the results of the Automated QA run in a snippet here
        HEREDOC
      end

      def sort_merge_requests
        IssuableSortByLabels.new(@merge_requests).sort_by_labels(*labels)
      end

      def formatter
        Formatters::MergeRequestsFormatter.new(sort_merge_requests)
      end

      def labels
        [Qa::TEAM_LABELS]
      end
    end
  end
end
