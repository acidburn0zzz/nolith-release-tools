require_relative '../username_extractor'

module Qa
  module Formatters
    class MergeRequestsFormatter
      STARTING_TITLE_DEPTH = 3
      SUBHEADING_SEPARATOR = "\n\n----\n\n".freeze

      def initialize(sorted_merge_requests)
        @merge_requests = sorted_merge_requests
      end

      def lines
        @lines ||= mr_lines(@merge_requests)
      end

      private

      def mr_lines(merge_requests, array = [], depth = 0)
        merge_requests.each do |title, v|
          array << title_line(title, depth)

          if v.is_a?(Hash)
            mr_lines(v, array, depth + 1)
          else
            v.each { |mr| array << mr_line(mr) }
            array << SUBHEADING_SEPARATOR
          end
        end
        array
      end

      def title_line(title, depth)
        "#{heading_string(depth)} #{title} #{format_label(title)} \n"
      end

      def heading_string(depth)
        '#' * (STARTING_TITLE_DEPTH + depth)
      end

      def mr_line(mr)
        "- [ ] #{username_to_mention(mr)} | [#{mr.title}](#{mr.web_url}) #{format_labels(mr.labels)}"
      end

      def username_to_mention(mr)
        UsernameExtractor.new(mr).extract_username
      end

      def format_labels(labels)
        labels.map { |label| format_label(label) }.join(' ')
      end

      def format_label(label)
        %[~"#{label}"]
      end
    end
  end
end
