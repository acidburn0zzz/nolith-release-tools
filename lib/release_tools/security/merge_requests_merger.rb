# frozen_string_literal: true

module ReleaseTools
  module Security
    # Merging of valid security merge requests across different projects.
    class MergeRequestsMerger
      attr_reader :client

      ERROR_TEMPLATE = <<~ERROR.strip
        @%<author_username>s

        This merge request could not be merged automatically. Please rebase this
        merge request with the target branch and resolve any conflicts that may
        appear. Once resolved and the pipelines have passed, assign this merge
        request back to me and mark this discussion as resolved.

        #{MergeRequestsValidator::ERROR_FOOTNOTE}
      ERROR

      # @param [TrueClass|FalseClass] merge_master If merge requests that target
      # `master` should also be merged.
      def initialize(merge_master: false)
        @merge_master = merge_master
        @client = Client.new
      end

      # Merges all valid security merge requests.
      def execute
        valid = validated_merge_requests

        tuples = Parallel.map(valid, in_threads: Etc.nprocessors) do |mr|
          [merge(mr), mr]
        end

        merge_result = MergeResult.from_array(tuples)

        Slack::ChatopsNotification.merged_security_merge_requests(merge_result)
      end

      def validated_merge_requests
        valid = MergeRequestsValidator.new.execute

        if @merge_master
          valid
        else
          valid.reject { |mr| mr.target_branch == 'master' }
        end
      end

      # @param [Gitlab::ObjectifiedHash] mr
      def merge(mr)
        merged_mr = client.accept_merge_request(mr.project_id, mr.iid)

        if merged_mr.respond_to?(:merge_commit_sha) && merged_mr.merge_commit_sha
          true
        else
          reassign_merge_request(mr)

          false
        end
      end

      # @param [Gitlab::ObjectifiedHash] mr
      def reassign_merge_request(mr)
        client.create_merge_request_discussion(
          mr.project_id,
          mr.iid,
          body: format(ERROR_TEMPLATE, author_username: mr.author.username)
        )

        client.update_merge_request(
          mr.project_id,
          mr.iid,
          assignee_id: mr.author.id
        )
      end
    end
  end
end
