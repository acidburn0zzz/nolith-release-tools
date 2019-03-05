# frozen_string_literal: true

require 'version_sorter'

module ReleaseTools
  module Services
    class SecurityPreparationService
      def next_versions
        latest_versions(current_versions).map do |version|
          ReleaseTools::Version.new(version).next_patch
        end
      end

      private

      def current_versions
        ReleaseTools::VersionClient
          .versions
          .collect(&:version)
      end

      # Given an Array of version strings, find the three latest by minor number
      #
      # Example:
      #
      #   three_latest_versions(['1.0.0', '1.1.0', '1.1.1', '1.2.3'])
      #   => ['1.2.3', '1.1.1', '1.0.0']
      def latest_versions(versions)
        ::VersionSorter.rsort(versions).uniq do |version|
          version.split('.').take(2)
        end.take(3)
      end
    end
  end
end
