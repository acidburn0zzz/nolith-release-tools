module CherryPick
  # Performs automated cherry picking to a preparation branch for the specified
  # version.
  #
  # For the given project, this service will look for merged merge requests on
  # that project labeled `Pick into X.Y` and attempt to cherry-pick their merge
  # commits into the preparation merge request for the specified version.
  #
  # It will post a comment to each merge request with the status of the pick,
  # and then a final summary message to the preparation merge request with the
  # list of picked and unpicked merge requests for the release managers to
  # perform any further manual actions.
  class Service
    # TODO (rspeicher): Support `SharedStatus.security_release?`
    REMOTE = :gitlab

    attr_reader :project
    attr_reader :version

    def initialize(project, version)
      @project = project
      @version = version

      assert_version!

      @prep_mr = PreparationMergeRequest.new(version: version)

      assert_prep_mr!

      @prep_branch = @prep_mr.preparation_branch_name
      @results = []
    end

    def execute
      return unless pickable_mrs.any?

      pickable_mrs.each do |merge_request|
        cherry_pick(merge_request)
      end

      notifier.summary(
        @results.select(&:success?),
        @results.select(&:failure?)
      )
    end

    private

    attr_reader :repository

    def assert_version!
      raise "Invalid version provided: `#{version}`" unless version.valid?
    end

    def assert_prep_mr!
      unless @prep_mr.exists?
        raise "Preparation merge request not found for `#{version}`"
      end
    end

    def notifier
      @notifier ||= ::CherryPick::CommentNotifier.new(version, @prep_mr)
    end

    def cherry_pick(merge_request)
      result = nil

      GitlabClient.cherry_pick(
        project,
        ref: merge_request.merge_commit_sha,
        target: @prep_branch
      )

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
