# frozen_string_literal: true

module ReleaseTools
  module CherryPick
    # Performs automated cherry picking to a target branch for the specified
    # version.
    #
    # For the given project, this service will look for merged merge requests on
    # that project labeled `Pick into X.Y` and attempt to cherry-pick their merge
    # commits into the target merge request for the specified version.
    #
    # It will post a comment to each merge request with the status of the pick,
    # and a final summary message with the list of picked and unpicked merge
    # requests for the release managers to perform any further manual actions.
    class Service
      # TODO (rspeicher): Support `SharedStatus.security_release?`
      REMOTE = :gitlab

      attr_reader :project
      attr_reader :version
      attr_reader :target

      def initialize(project, version, target)
        @project = project
        @version = version
        @target = target

        assert_version!
        assert_target!

        @target_branch = @target.branch_name

        @results = []
      end

      def execute
        return [] unless pickable_mrs.any?

        pickable_mrs.auto_paginate do |merge_request|
          cherry_pick(merge_request)
        end

        notifier.summary(
          @results.select(&:success?),
          @results.select(&:failure?)
        )

        notifier.blog_post_summary(@results.select(&:success?))

        @results
      end

      private

      attr_reader :repository

      def assert_version!
        raise "Invalid version provided: `#{version}`" unless version.valid?
      end

      def assert_target!
        raise 'Invalid cherry-pick target provided' unless target.exists?
      end

      def notifier
        if SharedStatus.dry_run?
          @notifier ||= ConsoleNotifier.new(version, target: target)
        else
          @notifier ||= CommentNotifier.new(version, target: target)
        end
      end

      def cherry_pick(merge_request)
        result = nil

        unless SharedStatus.dry_run?
          GitlabClient.cherry_pick(
            project,
            ref: merge_request.merge_commit_sha,
            target: @target_branch
          )
        end

        result = Result.new(merge_request, :success)
      rescue Gitlab::Error::Error
        result = Result.new(merge_request, :failure)
      ensure
        record_result(result)
      end

      def record_result(result)
        @results << result
        notifier.comment(result)
      end

      def pickable_mrs
        @pickable_mrs ||=
          GitlabClient.merge_requests(
            project,
            state: 'merged',
            labels: PickIntoLabel.for(version),
            order_by: 'created_at',
            sort: 'asc'
          )
      end
    end
  end
end
