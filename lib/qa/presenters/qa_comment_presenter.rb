require_relative '../username_extractor'

module Qa
  module Presenters
    class QaCommentPresenter
      def initialize(merge_requests)
        @merge_requests = merge_requests
      end

      def present
        "New QA items for: #{usernames.join(' ')}"
      end

      private

      def usernames
        @merge_requests.map do |merge_request|
          UsernameExtractor.new(merge_request).extract_username
        end
      end
    end
  end
end
