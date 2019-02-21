# frozen_string_literal: true

module ReleaseTools
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
          (+"").tap do |text|
            if issue.exists?
              text << issue.remote_issuable.description
            else
              text << header_text
            end
            text << formatter.lines.join("\n")
            text << automated_qa_text
          end
        end

        private

        def header_text
          <<~HEREDOC
            ## Process

            Each engineer validates and checks off each of their assigned QA task(s).
            1. Check off each Merge Request changes that you've tested successfully and note any issues you've created and check them off as they are resolved.
            1. If a problem is found:
               * Create an issue for it and add a sub bullet item under the corresponding validation checklist task. Link the issue there.
               * Add the severity label
               * Raise the problem in the discussion and tag relevant Engineering and Product managers.
            1. If a regression is found:
               * Create an issue for it
               * Add the severity label and the regression label
               * Raise the regression in the discussion and tag relevant Engineering and Product managers.

            General Quality info can be found in the [Quality Handbook](https://about.gitlab.com/handbook/engineering/quality/).

            ## Deadline

            QA testing on [staging.gitlab.com](https://staging.gitlab.com) for this issue should be completed by **#{due_date.strftime('%Y-%m-%d %H:%M')} UTC**.
            After this deadline has passed, Release Managers will proceed with the canary and production deployment.

            ## Merge Requests tested in #{version}

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

        def due_date
          utc_date = DateTime.now.new_offset(0)

          if version.rc == 1
            utc_date + 24.hours
          else
            utc_date + 12.hours
          end
        end
      end
    end
  end
end
