module Slack
  class Webhook
    NoWebhookURLError = Class.new(StandardError)
    CouldNotPostError = Class.new(StandardError)

    def self.webhook_url
      raise NoWebhookURLError
    end

    def self.fire_hook(text:, channel: nil)
      body = { text: text }
      body[:channel] = channel if channel

      response = HTTParty.post(webhook_url, { body: body.to_json })

      raise CouldNotPostError.new(response.inspect) unless response.code == 200
    end
  end
end
