# frozen_string_literal: true

module ReleaseTools
  module AutoDeploy
    class Naming
      BRANCH_FORMAT = '%<major>d-%<minor>d-auto-deploy-%<pipeline_id>07d'
      TAG_FORMAT = '%<major>d.%<minor>d.%<timestamp>d+%<ee_ref>.11s.%<omnibus_ref>.11s'

      def self.branch
        new.branch
      end

      def self.tag(timestamp:, omnibus_ref:, ee_ref:)
        new.tag(
          timestamp: timestamp,
          omnibus_ref: omnibus_ref,
          ee_ref: ee_ref
        )
      end

      def initialize
        @pipeline_id = ENV.fetch('CI_PIPELINE_IID') do |key|
          raise ArgumentError, "`#{key}` must be set in order to proceed"
        end
      end

      def branch
        format(
          BRANCH_FORMAT,
          major: version.first,
          minor: version.last,
          pipeline_id: @pipeline_id
        )
      end

      def tag(timestamp:, omnibus_ref:, ee_ref:)
        format(
          TAG_FORMAT,
          major: version.first,
          minor: version.last,
          timestamp: timestamp,
          omnibus_ref: omnibus_ref,
          ee_ref: ee_ref
        )
      end

      def version
        @version ||=
          begin
            milestone = ReleaseTools::GitlabClient
              .current_milestone
              .title

            unless milestone.match?(/\A\d+\.\d+\z/)
              raise ArgumentError, "Invalid version from milestone: #{milestone}"
            end

            milestone.split('.')
          end
      end
    end
  end
end
