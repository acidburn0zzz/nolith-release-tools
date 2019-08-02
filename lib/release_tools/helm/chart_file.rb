# frozen_string_literal: true

module ReleaseTools
  module Helm
    class ChartFile
      include ::SemanticLogger::Loggable

      attr_reader :metadata

      def initialize(filepath)
        unless filepath && File.exist?(filepath)
          logger.fatal('Chart file must exist', path: filepath)
          exit 1
        end
        @filepath = filepath

        logger.info('Reading chart file', path: @filepath)
        @metadata = YAML.safe_load(File.read(@filepath))
      end

      def name
        @metadata['name']
      end

      def version
        HelmChartVersion.new(@metadata['version'])
      end

      def app_version
        HelmGitlabVersion.new(@metadata['appVersion'])
      end

      def update_versions(chart_version = nil, app_version = nil)
        @metadata['version'] = chart_version.to_s if chart_version
        @metadata['appVersion'] = app_version.to_s if app_version

        logger.info('Updating chart file', path: @filepath)
        File.write(@filepath, YAML.dump(@metadata))
      end
    end
  end
end
