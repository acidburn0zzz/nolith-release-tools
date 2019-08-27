# frozen_string_literal: true

module ReleaseTools
  module Services
    class SyncRemotesService
      include ::SemanticLogger::Loggable

      def initialize(version)
        @version = version.to_ce
        @omnibus = OmnibusGitlabVersion.new(@version.to_omnibus)
      end

      def execute
        if Feature.disabled?(:publish_git)
          logger.warn('The `publish_git` feature is disabled.')
          return
        end

        if Feature.disabled?(:publish_git_push)
          logger.info('The `publish_git_push` feature is disabled. Nothing will be pushed.')
        end

        sync_tags(Project::GitlabEe, @version.tag(ee: true))
        sync_tags(Project::GitlabCe, @version.tag(ee: false))
        sync_tags(Project::OmnibusGitlab, @omnibus.to_ee.tag, @omnibus.to_ce.tag)

        sync_branches(Project::GitlabEe, @version.stable_branch(ee: true))
        sync_branches(Project::GitlabCe, @version.stable_branch(ee: false))
        sync_branches(Project::OmnibusGitlab, *[
          @omnibus.to_ee.stable_branch, @omnibus.to_ce.stable_branch
        ].uniq) # Omnibus uses a single branch post-12.2
      end

      private

      def sync_tags(project, *tags)
        repository = RemoteRepository.get(project.remotes, global_depth: 1)

        tags.each do |tag|
          logger.info('Fetching tag', tag: tag)

          repository.fetch("refs/tags/#{tag}", remote: :dev)

          if Feature.enabled?(:publish_git_push) # rubocop:disable Style/Next
            logger.info('Pushing to all remotes', tag: tag)

            repository.push_to_all_remotes(tag)
          end
        end
      end

      def sync_branches(project, *branches)
        branches.each do |branch|
          repository = RemoteRepository.get(
            project.remotes.slice(:gitlab, :dev), # Clone from production first
            global_depth: 50,
            branch: branch
          )

          repository.fetch(branch, remote: :dev)

          result = repository.merge("dev/#{branch}", branch, no_ff: true)

          logger.debug(
            __method__,
            branch: branch,
            result: {
              status: result.status.exitstatus,
              output: result.output
            }
          )

          if Feature.enabled?(:publish_git_push) # rubocop:disable Style/Next
            # TODO (rspeicher): Check `result` status
            # TODO (rspeicher): Handle merge conflicts (message? fail?)

            repository.push_to_all_remotes(branch)
          end
        end
      end
    end
  end
end
