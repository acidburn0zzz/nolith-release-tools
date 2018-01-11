require_relative 'time_util'

class SlackWebhook
  NoWebhookURLError = Class.new(StandardError)
  CouldNotPostError = Class.new(StandardError)

  attr_reader :webhook_url

  def self.new_merge_request(merge_request)
    text = <<~SLACK_MESSAGE.strip
      A new merge request has been created: <#{merge_request.url}>
    SLACK_MESSAGE

    new.fire_hook(text: text)
  end

  def self.existing_merge_request(merge_request)
    created_at = Time.parse(merge_request.created_at)
    text = <<~SLACK_MESSAGE.strip
      Tried to create a new merge request but <#{merge_request.url}|this one> from #{TimeUtil.time_ago(created_at)} is still pending!
    SLACK_MESSAGE

    new.fire_hook(text: text)
  end

  def self.missing_merge_request(merge_request)
    text = <<~SLACK_MESSAGE.strip
      The latest upstream merge MR could not be created! Please have a look at https://gitlab.com/gitlab-org/release-tools/-/jobs/#{ENV['CI_JOB_ID']}.
    SLACK_MESSAGE

    new.fire_hook(text: text)
  end

  def initialize
    @webhook_url = ENV['CI_SLACK_WEBHOOK_URL']

    raise NoWebhookURLError unless webhook_url
  end

  def fire_hook(text:, channel: nil)
    options = { body: { text: text } }
    options[:body][:channel] = channel if channel

    response = HTTParty.post(webhook_url, options)

    raise CouldNotPostError.new(response.inspect) unless response.code == 200
  end
end
