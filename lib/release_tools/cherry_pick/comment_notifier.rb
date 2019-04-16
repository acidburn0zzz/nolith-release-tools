# frozen_string_literal: true

module ReleaseTools
  module CherryPick
    class CommentNotifier
      attr_reader :version
      attr_reader :prep_mr
      attr_reader :branch_name

      def initialize(version, prep_mr: nil, branch_name: nil)
        @version = version
        @prep_mr = prep_mr
        @branch_name = branch_name
      end

      def comment(pick_result)
        if pick_result.success?
          successful_comment(pick_result)
        else
          failure_comment(pick_result)
        end
      end

      # Post a summary comment in the preparation merge request with a list of
      # picked and unpicked merge requests
      #
      # picked   - Array of successful Results
      # unpicked - Array of failure Results
      def summary(picked, unpicked)
        return if picked.empty? && unpicked.empty?
        return unless prep_mr

        message = []

        if picked.any?
          message << <<~MSG
            Successfully picked the following merge requests:

            #{markdown_list(picked.collect(&:url))}
          MSG
        end

        if unpicked.any?
          message << <<~MSG
            Failed to pick the following merge requests:

            #{markdown_list(unpicked.collect(&:url))}
          MSG
        end

        create_merge_request_comment(prep_mr, message.join("\n"))
      end

      def blog_post_summary(picked)
        return if version.rc?
        return if picked.empty?

        notify_object = prep_mr&.url || branch_name

        message = <<~MSG
          The following merge requests were picked into #{notify_object}:

          ```
          #{markdown_list(picked.collect(&:to_markdown))}
          ```
        MSG

        return message unless prep_mr

        create_issue_comment(prep_mr.release_issue, message)
      end

      private

      def markdown_list(array)
        array.map { |v| "* #{v}" }.join("\n")
      end

      def successful_comment(pick_result)
        notify_object = prep_mr&.url || branch_name

        comment = <<~MSG
          Automatically picked into #{notify_object}, will merge into
          `#{version.stable_branch}` ready for `#{version}`.

          /unlabel #{PickIntoLabel.reference(version)}
        MSG

        return unless prep_mr

        create_merge_request_comment(pick_result.merge_request, comment)
      end

      def failure_comment(pick_result)
        author = pick_result
          .merge_request
          .author
          .username

        comment = <<~MSG
          @#{author} This merge request could not automatically be picked into
          `#{version.stable_branch}` for `#{version}` and will need manual
          intervention.
        MSG

        create_merge_request_comment(pick_result.merge_request, comment)
      end

      def client
        GitlabClient
      end

      def create_issue_comment(issue, comment)
        client.create_issue_note(
          issue.project,
          issue: issue,
          body: comment
        )
      end

      def create_merge_request_comment(merge_request, comment)
        client.create_merge_request_comment(
          merge_request.project_id,
          merge_request.iid,
          comment
        )
      end
    end
  end
end
