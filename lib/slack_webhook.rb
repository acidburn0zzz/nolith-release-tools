require_relative 'time_util'

class SlackWebhook
  NoWebhookURLError = Class.new(StandardError)
  CouldNotPostError = Class.new(StandardError)

  attr_reader :webhook_url

  def self.new_merge_request(merge_request)
    conflict_message = merge_request_conflict_message(merge_request)

    text = <<~SLACK_MESSAGE.strip
      Created a new merge request <#{merge_request.url}|#{merge_request.to_reference}> #{conflict_message}
    SLACK_MESSAGE

    new.fire_hook(text: text)
  end

  def self.merge_request_conflict_message(merge_request)
    return if merge_request.conflicts.nil?

    conflict_count = merge_request.conflicts.count

    if conflict_count.zero?
      'with no conflicts! :tada:'
    else
      "with #{conflict_count} conflict".pluralize(conflict_count) + '! :warning:'
    end
  end

  def self.existing_merge_request(merge_request)
    text = <<~SLACK_MESSAGE.strip
      Tried to create a new merge request but <#{merge_request.url}|#{merge_request.to_reference}> from #{TimeUtil.time_ago(merge_request.created_at)} is still pending! :hourglass:
    SLACK_MESSAGE

    new.fire_hook(text: text)
  end

  def self.missing_merge_request
    text = <<~SLACK_MESSAGE.strip
      The latest upstream merge MR could not be created! Please have a look at <https://gitlab.com/gitlab-org/release-tools/-/jobs/#{ENV['CI_JOB_ID']}>.
    SLACK_MESSAGE

    new.fire_hook(text: text)
  end

  def initialize
    @webhook_url = ENV['CI_SLACK_WEBHOOK_URL']

    raise NoWebhookURLError unless webhook_url
  end

  def fire_hook(text:, channel: nil)
    body = { text: text }
    body[:channel] = channel if channel

    response = HTTParty.post(webhook_url, { body: body.to_json })

    raise CouldNotPostError.new(response.inspect) unless response.code == 200
  end
end
