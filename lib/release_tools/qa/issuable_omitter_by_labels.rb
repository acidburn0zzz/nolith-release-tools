# frozen_string_literal: true

module ReleaseTools
  module Qa
    class IssuableOmitterByLabels
      def initialize(issuables, unpermitted_labels)
        @issuables = issuables
        @unpermitted_labels = unpermitted_labels
      end

      def execute
        @issuables.reject do |issuable|
          (issuable.labels & @unpermitted_labels).any?
        end
      end
    end
  end
end
