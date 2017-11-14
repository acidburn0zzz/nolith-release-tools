require_relative '../project/gitlab_ce'
require_relative '../project/gitlab_ee'
require_relative '../upstream_merge'
require_relative '../upstream_merge_request'

module Services
  class UpstreamMergeService
    UpstreamMergeAlreadyInProgressError = Class.new(StandardError)

    Result = Struct.new(:success?, :payload)

    def perform(dry_run: false, mention_people: false, force: false)
      check_for_open_upstream_mrs!(force)

      merge_request = UpstreamMergeRequest.new(mention_people: mention_people)
      merge = UpstreamMerge.new(
        origin: Project::GitlabEe.remotes[:gitlab],
        upstream: Project::GitlabCe.remotes[:gitlab],
        merge_branch: merge_request.source_branch)
      merge_request.conflicts = merge.execute

      merge_request.create unless dry_run

      Result.new(true, { upstream_mr: merge_request })
    rescue UpstreamMergeAlreadyInProgressError
      return Result.new(false, { in_progress_mr_url: open_merge_requests.first.web_url })
    end

    private

    def check_for_open_upstream_mrs!(force = false)
      if !force && open_merge_requests.any?
        raise UpstreamMergeAlreadyInProgressError
      end
    end

    def open_merge_requests
      @open_merge_requests ||= UpstreamMergeRequest.open_mrs
    end
  end
end
