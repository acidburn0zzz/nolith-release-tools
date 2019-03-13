# frozen_string_literal: true

module ReleaseTools
  module CherryPick
    class CommentNotifier
      attr_reader :version
      attr_reader :prep_mr

      def initialize(version, prep_mr)
        @version = version
        @prep_mr = prep_mr
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
        return if picked.empty?

        message = <<~MSG
          The following Markdown can be added to the blog post:

          ```
          #{markdown_list(picked.collect(&:to_markdown))}
          ```
        MSG

        create_merge_request_comment(prep_mr, message)
      end

      private

      def markdown_list(array)
        array.map { |v| "* #{v}" }.join("\n")
      end

      def successful_comment(pick_result)
        comment = <<~MSG
          Automatically picked into #{prep_mr.url}, will merge into
          `#{version.stable_branch}` ready for `#{version}`.

          /unlabel #{PickIntoLabel.reference(version)}
        MSG

        create_merge_request_comment(pick_result.merge_request, comment)
      end

      def failure_comment(pick_result)
        comment = <<~MSG
          This merge request could not automatically be picked into
          `#{version.stable_branch}` for `#{version}` and will need manual
          intervention.
        MSG

        create_merge_request_comment(pick_result.merge_request, comment)
      end

      def client
        GitlabClient
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
