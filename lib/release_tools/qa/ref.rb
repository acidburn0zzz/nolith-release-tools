# frozen_string_literal: true

module ReleaseTools
  module Qa
    class Ref
      TAG_REGEX = /(?<prefix>\w?)(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)(-rc?(?<rc>\d+))?/.freeze
      STABLE_BRANCH_REGEX = /^(?<major>\d+)-(?<minor>\d+)-(?<stable>stable)$/.freeze

      attr_reader :ref

      def initialize(ref)
        @ref = ref
      end

      def for_project(project)
        if project == ReleaseTools::Project::GitlabEe && should_be_converted?
          "#{ref}-ee"
        else
          ref
        end
      end

      private

      def should_be_converted?
        tag? || stable_branch?
      end

      def tag?
        ref.match(TAG_REGEX)
      end

      def stable_branch?
        ref.match(STABLE_BRANCH_REGEX)
      end
    end
  end
end
