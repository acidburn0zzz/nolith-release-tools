module Slack
  class Webhook
    NoWebhookURLError = Class.new(StandardError)
    CouldNotPostError = Class.new(StandardError)

    attr_reader :webhook_url

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
end
