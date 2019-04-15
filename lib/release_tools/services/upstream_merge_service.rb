# frozen_string_literal: true

module ReleaseTools
  module Services
    class UpstreamMergeService
      UpstreamMergeInProgressError = Class.new(StandardError)

      Result = Struct.new(:success?, :payload)

      attr_reader :dry_run, :mention_people, :force

      def initialize(dry_run: false, mention_people: false, force: false)
        @dry_run = dry_run
        @mention_people = mention_people
        @force = force
      end

      def perform
        check_for_open_upstream_mrs! unless force

        merge = UpstreamMerge.new(
          origin: Project::GitlabEe.remotes[:gitlab],
          upstream: Project::GitlabCe.remotes[:gitlab],
          source_branch: upstream_merge_request.source_branch
        )
        upstream_merge_request.conflicts = merge.execute!

        unless dry_run
          upstream_merge_request.create

          unless upstream_merge_request.conflicts?
            # HACK: Insert an arbitrary delay to avoid merging before CI has a
            # chance to pick up the new push
            #
            # See https://gitlab.com/gitlab-org/release-tools/issues/246
            sleep 30 unless ENV['TEST']

            upstream_merge_request.approve
            upstream_merge_request.accept
          end
        end

        Result.new(true, upstream_mr: upstream_merge_request)
      rescue UpstreamMerge::DownstreamAlreadyUpToDate
        Result.new(false, already_up_to_date: true)
      rescue UpstreamMergeInProgressError
        Result.new(false, in_progress_mr: open_merge_requests.first)
      end

      def upstream_merge_request
        @upstream_merge_request ||= UpstreamMergeRequest.new(mention_people: mention_people)
      end

      private

      def check_for_open_upstream_mrs!
        raise UpstreamMergeInProgressError if open_merge_requests.any?
      end

      def open_merge_requests
        @open_merge_requests ||= UpstreamMergeRequest.open_mrs.map do |upstream_mr|
          UpstreamMergeRequest.new(upstream_mr.to_h)
        end
      end
    end
  end
end
