require_relative '../project/gitlab_ce'
require_relative '../project/gitlab_ee'
require_relative '../upstream_merge'
require_relative '../upstream_merge_request'

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
        merge_branch: upstream_merge_request.source_branch)
      upstream_merge_request.conflicts = merge.execute!

      unless dry_run
        upstream_merge_request.create
        # The following doesn't currently work until we implements approvals
        # https://gitlab.com/gitlab-org/release-tools/issues/177
        # upstream_merge_request.accept unless upstream_merge_request.conflicts?
      end

      Result.new(true, { upstream_mr: upstream_merge_request })
    rescue UpstreamMerge::DownstreamAlreadyUpToDate
      Result.new(false, { already_up_to_date: true })
    rescue UpstreamMergeInProgressError
      return Result.new(false, { in_progress_mr: open_merge_requests.first })
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
