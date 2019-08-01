# frozen_string_literal: true

module ReleaseTools
  module Services
    class BasePublishService
      class PipelineNotFoundError < StandardError
        def initialize(version)
          super("Pipeline not found for #{version}")
        end
      end

      def initialize(version)
        @version = version
      end

      def play_stages
        raise NotImplementedError
      end

      def release_versions
        raise NotImplementedError
      end

      def project
        raise NotImplementedError
      end

      def execute
        release_versions.each do |version|
          pipeline = client
            .pipelines(project, scope: :tags, ref: version)
            .first

          raise PipelineNotFoundError.new(version) unless pipeline

          triggers = client
            .pipeline_jobs(project, pipeline.id, scope: :manual)
            .auto_paginate
            .select { |job| play_stages.include?(job.stage) }

          if triggers.any?
            $stdout.puts "--> #{version}: #{pipeline.web_url}"

            triggers.each do |job|
              if SharedStatus.dry_run?
                $stdout.puts "    #{job.name}: #{job.web_url.colorize(:yellow)}"
              else
                $stdout.puts "    #{job.name}: #{job.web_url.colorize(:green)}"
                client.job_play(project_path, job.id)
              end
            end

            $stdout.puts
          else
            warn "Nothing to be done for #{version}: #{pipeline.web_url}"
          end
        end
      end

      private

      def project_path
        project.dev_path
      end

      def client
        @client ||= GitlabDevClient
      end
    end
  end
end
