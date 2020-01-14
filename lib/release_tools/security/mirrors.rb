# frozen_string_literal: true

module ReleaseTools
  module Security
    class Mirrors
      include ::SemanticLogger::Loggable

      NotFoundError = Class.new(StandardError)

      def self.disable
        new.disable
      end

      def self.enable
        new.enable
      end

      def initialize
        @client = Client.new
      end

      def disable
        update(enabled: false)
      end

      def enable
        update(enabled: true)
      end

      # Update each Security mirror with specified attributes
      def update(options = {})
        Parallel.each(canonical_projects, in_threads: Etc.nprocessors) do |project|
          mirror = security_mirror(project)
          next unless mirror

          logger.info(
            'Updating mirror',
            project: project.path_with_namespace,
            mirror: mirror.url,
            **options
          )

          @client.put(
            "/projects/#{project.id}/remote_mirrors/#{mirror.id}",
            options.dup # https://github.com/NARKOZ/gitlab/pull/542
          )
        end

        true
      end

      private

      # Given Security projects, fetch attributes for their Canonical projects
      def canonical_projects
        @canonical_projects ||= Parallel.map(security_projects) do |project|
          # rubocop:disable Style/RedundantBegin
          begin
            @client.project(project.forked_from_project.id)
          rescue ::Gitlab::Error::Error => ex
            logger.warn(
              'Failed to fetch Canonical project',
              project: project.forked_from_project.path_with_namespace,
              error: ex.message
            )

            nil
          end
          # rubocop:enable Style/RedundantBegin
        end.compact
      end

      # Fetch attributes for each project in the `gitlab-org/security` group
      def security_projects
        @security_projects ||= @client
          .group_projects('gitlab-org/security')
          .select { |p| p.respond_to?(:forked_from_project) }
      end

      # Find a Canonical project's Security mirror
      #
      # project - Canonical Project object
      def security_mirror(project)
        @client
          .get("/projects/#{project.id}/remote_mirrors")
          .detect(-> { raise NotFoundError }) { |m| m.url.include?('/gitlab-org/security/') }
      rescue NotFoundError, ::Gitlab::Error::NotFound, ::Gitlab::Error::Unauthorized => ex
        logger.warn(
          'Security mirror not found',
          project: project.path_with_namespace,
          error: ex.message
        )

        nil
      end
    end
  end
end
