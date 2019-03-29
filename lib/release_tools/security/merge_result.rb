# frozen_string_literal: true

module ReleaseTools
  module Security
    class MergeResult
      def self.from_array(valid: [], invalid: [])
        merged = []
        not_merged = []

        valid.each do |(did_merge, mr)|
          if did_merge
            merged << mr
          else
            not_merged << mr
          end
        end

        new(merged: merged, not_merged: not_merged, invalid: invalid)
      end

      def initialize(merged: [], not_merged: [], invalid: [])
        @merged = merged
        @not_merged = not_merged
        @invalid = invalid
      end

      def merge_request_attachment_fields(merge_requests)
        merge_requests.group_by(&:target_branch).map do |(target_branch, mrs)|
          {
            title: "Branch: #{target_branch}",
            value: mrs.map { |mr| "<#{mr.web_url}|!#{mr.iid}>" }.join(', '),
            short: false
          }
        end
      end

      def slack_attachments
        attachments = []

        if @merged.any?
          attachments << {
            fallback: "Merged: #{@merged.length}",
            title: ":heavy_check_mark: Merged: #{@merged.length}",
            color: 'good'
          }
        end

        if @invalid.any?
          attachments << {
            fallback: "Invalid and reassigned: #{@invalid.length}",
            title: ":warning: Invalid and reassigned: #{@invalid.length}",
            color: 'warning',
            fields: merge_request_attachment_fields(@invalid)
          }
        end

        if @not_merged.any?
          attachments << {
            fallback: "Failed to merge: #{@not_merged.length}",
            title: ":x: Failed to merge: #{@not_merged.length}",
            color: 'danger',
            fields: merge_request_attachment_fields(@not_merged)
          }
        end

        attachments
      end
    end
  end
end
