require_relative '../issuable_sort_by_labels'
require_relative '../formatters/merge_requests_formatter'

module Qa
  module Presenters
    class IssuePresenter
      attr_reader :merge_requests, :issue, :version

      def initialize(merge_requests, issue, version)
        @merge_requests = merge_requests
        @issue = issue
        @version = version
      end

      def present
        "".tap do |text|
          if issue.exists?
            text << issue.remote_issuable.description
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
          ## Process

          A Release manager with the help of a Quality engineer will populate the [Merge Requests tested](#merge-requests-tested) section. The information is taken from our Automated QA task generation script. The documentation can be found at: https://gitlab.com/gitlab-org/release/docs/blob/master/general/qa-issue-generation.md

          Each engineer then validates and checks off each of their assigned QA task(s).
          1. Check off each Merge Request changes that you've tested successfully and note any issues you've created and check them off as they are resolved.
          1. If a problem is found:
            * Create an issue for it and add a sub bullet item under the corresponding validation checklist task. Link the issue there.
            * Add the severity label
            * Raise the problem in the discussion and tag relevant Engineering and Product managers.
          1. If a regression is found:
            * Create an issue for it
            * Add the severity label and the regression label
            * Raise the regression in the discussion and tag relevant Engineering and Product managers.

          General Quality info can be found in the [Quality Handbook](https://about.gitlab.com/handbook/quality/).

          ## Deadline

          * The deadline to which the first release candidate (RC1) moves on from staging environment is **24** hours after the deploy to staging completes.
          * The deadline to which subsequent release candidates moves on from staging environment is **12** hours after the deploy to staging completes.

          > **Note:** For Release Managers, for each release candidate, update the time here to reflect the latest release candidate deploy.

          QA testing on [staging.gitlab.com](https://staging.gitlab.com) should be completed by **YYYY-MM-DD HH:MM UTC**.
          After this deadline has passed, Release Managers will proceed with the canary and production deployment.
        HEREDOC
      end

      def changes_header
        <<~HEREDOC
          ## Merge Requests tested in #{version}

          > Example:
          >
          > * [x] `@Engineer1` | Apply notification settings level of bacons to all child bacons ~Discussion ~groups ~subgroups
          > * [x] `@Engineer2` | Resolve "Timeout searching group bacons" ~Discussion ~backend ~bug ~database ~groups ~issues ~performance
          > * [ ] `@Engineer3` | Nonnegative meatball weights in issuable sidebar short ribs ~Deliverable ~Discussion ~backend ~direction ~frontend ~issues
          >   * Found problem, does not work because... [LINK_ISSUE_HERE](https://gitlab.com/gitlab-org/gitlab-ce/issues/)
          > * [ ] `@Engineer4` | Moving rev-list pastrami bacons to Lfs Prosciutto ~Platform ~backend ~lfs
        HEREDOC
      end

      def automated_qa_text
        <<~HEREDOC
          ## Automated QA for #{version}

          If the last [`Daily staging QA` pipeline] was run for #{version},
          you can just report the result in this issue.

          Otherwise, start a new [`Daily staging QA` pipeline] by clicking the
          "Play" button and wait for the pipeline to finish.

          ```sh
          Post the result of the test run here.
          ```

          If there are errors, create a new issue for each failing job (you can
          use the "New issue" button from the job page itself), in the
          https://gitlab.com/gitlab-org/quality/staging project and mention
          the `@gl-quality` group.

          [`Daily staging QA` pipeline]: https://gitlab.com/gitlab-org/quality/staging/pipeline_schedules
        HEREDOC
      end

      def sort_merge_requests
        IssuableSortByLabels.new(merge_requests).sort_by_labels(*labels)
      end

      def formatter
        Formatters::MergeRequestsFormatter.new(
          merge_requests: sort_merge_requests,
          project_path: issue.project.path)
      end

      def labels
        [Qa::TEAM_LABELS]
      end
    end
  end
end
