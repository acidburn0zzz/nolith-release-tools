# frozen_string_literal: true

module ReleaseTools
  module Qa
    class IssuableOmitterByLabels
      attr_reader :issuables

      def initialize(issuables)
        @issuables = issuables
      end

      def execute
        issuables.select do |issuable|
          no_unpermitted_labels?(issuable) && permitted_with_team_labels?(issuable)
        end
      end

      private

      def no_unpermitted_labels?(issuable)
        (issuable.labels & UNPERMITTED_LABELS).empty?
      end

      def permitted_with_team_labels?(issuable)
        (issuable.labels & TEAM_LABELS).any? ||
          (issuable.labels & PERMITTED_WITH_TEAM_LABELS).empty?
      end
    end
  end
end
