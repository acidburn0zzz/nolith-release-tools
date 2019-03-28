# frozen_string_literal: true

module ReleaseTools
  module Qa
    class SecurityIssue < Qa::Issue
      def confidential?
        true
      end

      def title
        "#{version} Security QA Issue"
      end

      def labels
        super + ',security'
      end
    end
  end
end
