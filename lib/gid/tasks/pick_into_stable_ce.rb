require_relative 'task'

module Gid
  module Tasks
    class PickIntoStableCe < Tasks::Task
      MAX_PAGES = 3

      protected

      def run
        @stable_mrs = []

        pick_stable_mrs
        print_out_mrs

        pick_into_stable!
        push!
      end

      private

      def pick_stable_mrs
        Output::Logger.write('Finding Pick into Stable MRs...')

        merge_requests.each do |mr|
          next unless mr.milestone && mr.milestone.title == version
          next unless mr.labels.include?('Pick into Stable')
          # TODO: Check previous milestones

          @stable_mrs << StableMr.new(mr, version)
        end
      end

      def print_out_mrs
        @stable_mrs.each(&:to_log)
      end

      def pick_into_stable!
        return if @stable_mrs.empty?

        Output::Logger.write('Cherry-picking Stable MRs...')

        git_facade = Git::Facade.new(repo)
        git_facade.pull unless Config.dry_run

        # Start with the oldest - not accurate at all, since we don't know when it was actually merged.
        @stable_mrs.reverse_each do |mr|
          Output::Logger.write("Cherry-picking from MR #{mr.iid}")

          git_facade.cherry_pick(mr.merge_commit_sha) unless Config.dry_run

          mr.leave_note! unless Config.dry_run
        end
      end

      def push!
        Git::Facade.new(repo).push
      end

      # rubocop:disable Style/AsciiComments
      #
      # Finds/guesses the pick into stable MRs using the API.
      # This is a REALLY bad way, but there aren't any useful filters at all for this API ¯\_(ツ)_/¯
      # So we order by updated_at desc hoping most of the MRs will fall into the current release
      # TODO: Consider adding at least milestone_id to the optional params of the MRs API
      def merge_requests
        mr_chunks = []

        MAX_PAGES.times do |page|
          mr_chunks << Gitlab.merge_requests(project_id, query_options.merge(page: page + 1)).to_a
        end

        mr_chunks.flatten
      end
      # rubocop:enable Style/AsciiComments

      def version
        @options[:version].to_minor
      end

      def project_id
        Config.ce_project_id
      end

      def repo
        Config.ce_repo
      end

      def query_options
        {
          state: 'merged',
          order_by: 'updated_at',
          per_page: 20
        }
      end
    end
  end
end
