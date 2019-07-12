# frozen_string_literal: true

module ReleaseTools
  module Services
    class CNGPublishService < BasePublishService
      def play_stages
        @play_stages ||= %w[release].freeze
      end

      def release_versions
        @release_versions ||= [@version.to_ce.tag, @version.to_ee.tag]
      end

      def project
        @project ||= Project::CNGImage
      end
    end
  end
end
