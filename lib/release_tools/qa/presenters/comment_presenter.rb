# frozen_string_literal: true

module ReleaseTools
  module Qa
    module Presenters
      class CommentPresenter
        def initialize(merge_requests)
          @merge_requests = merge_requests
        end

        def present
          "New QA items for: #{usernames.join(' ')}"
        end

        private

        def usernames
          @merge_requests.map do |merge_request|
            ReleaseTools::Qa::UsernameExtractor.new(merge_request).extract_username
          end
        end
      end
    end
  end
end
