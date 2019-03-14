# frozen_string_literal: true

module ReleaseTools
  module Security
    class MergeResult
      def self.from_array(array)
        merged = []
        not_merged = []

        array.each do |(did_merge, mr)|
          if did_merge
            merged << mr
          else
            not_merged << mr
          end
        end

        new(merged: merged, not_merged: not_merged)
      end

      def initialize(merged: [], not_merged: [])
        @merged = merged
        @not_merged = not_merged
      end

      def not_merged_slack_attachment_fields
        @not_merged.group_by(&:target_branch).map do |(target_branch, mrs)|
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

        if @not_merged.any?
          attachments << {
            fallback: "Not merged: #{@not_merged.length}",
            title: ":x: Not merged: #{@not_merged.length}",
            color: 'danger',
            fields: not_merged_slack_attachment_fields
          }
        end

        attachments
      end
    end
  end
end
