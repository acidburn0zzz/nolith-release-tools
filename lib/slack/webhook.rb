require 'httparty'

module Slack
  class Webhook
    NoWebhookURLError = Class.new(StandardError)
    CouldNotPostError = Class.new(StandardError)

    def self.webhook_url
      raise NoWebhookURLError
    end

    def self.fire_hook(text:, channel: nil)
      # It's valid for a child class to return an empty String in order to
      # silently skip the notification, rather than aborting entirely
      return unless webhook_url.present?

      body = { text: text }
      body[:channel] = channel if channel

      response = HTTParty.post(webhook_url, { body: body.to_json })

      raise CouldNotPostError.new(response.inspect) unless response.code == 200
    end
  end
end
