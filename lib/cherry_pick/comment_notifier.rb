require 'active_support/core_ext/string/inflections'

module CherryPick
  class CommentNotifier
    attr_reader :version
    attr_reader :prep_mr

    def initialize(version, prep_mr)
      @version = version
      @prep_mr = prep_mr
    end

    def comment(pick_result)
      if pick_result.success?
        successful_comment(pick_result)
      else
        failure_comment(pick_result)
      end
    end

    private

    def client
      GitlabClient
    end

    def create_merge_request_comment(merge_request, comment)
      client.create_merge_request_comment(
        merge_request.project_id,
        merge_request.iid,
        comment
      )
    end

    def successful_comment(pick_result)
      url = prep_mr.url

      comment = <<~MSG
        Picked into #{url}, will merge into `#{version.stable_branch}`
        ready for `#{version}`.

        /unlabel #{PickIntoLabel.reference(version)}
      MSG

      create_merge_request_comment(pick_result.merge_request, comment)
    end

    def failure_comment(pick_result)
      conflicts = pick_result.conflicts.map { |conflict| "* #{conflict}" }
      conflict_message = "conflict".pluralize(conflicts)

      comment = <<~MSG
        This merge request could not be picked into `#{version.stable_branch}`
        for `#{version}` due to the following #{conflict_message}:

        #{conflicts.join("\n")}
      MSG

      create_merge_request_comment(pick_result.merge_request, comment)
    end
  end
end
