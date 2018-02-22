require_relative '../time_util'
require_relative '../ci'

module Slack
  class UpstreamMergeNotification < Webhook
    def self.webhook_url
      ENV['SLACK_UPSTREAM_MERGE_URL'] || super
    end

    def self.new_merge_request(merge_request)
      conflict_message = merge_request_conflict_message(merge_request)

      text = <<~MSG.strip
        Created a new merge request <#{merge_request.url}|#{merge_request.to_reference}> #{conflict_message}
      MSG

      fire_hook(text: text)
    end

    def self.merge_request_conflict_message(merge_request)
      return if merge_request.conflicts.nil?

      conflict_count = merge_request.conflicts.count

      if conflict_count.zero?
        'with no conflicts! :tada:.'
      else
        "with #{conflict_count} conflict".pluralize(conflict_count) + '! :warning:'
      end
    end

    def self.existing_merge_request(merge_request)
      text = <<~MSG.strip
        Tried to create a new merge request but <#{merge_request.url}|#{merge_request.to_reference}> from #{TimeUtil.time_ago(merge_request.created_at)} is still pending! :hourglass:
      MSG

      fire_hook(text: text)
    end

    def self.missing_merge_request
      text = <<~MSG.strip
        The latest upstream merge MR could not be created! Please have a look at <#{CI.current_job_url}>. :boom:
      MSG

      fire_hook(text: text)
    end

    def self.downstream_is_up_to_date
      text = <<~MSG.strip
        EE is already up-to-date with CE. No merge request was created. :tada:
      MSG

      fire_hook(text: text)
    end
  end
end
