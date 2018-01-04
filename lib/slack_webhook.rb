class SlackWebhook
  CouldNotPostError = Class.new(StandardError)

  attr_reader :webhook_url

  def initialize(webhook_url)
    @webhook_url = webhook_url
  end

  def fire_hook(text:, channel: nil)
    options = { body: { text: text } }
    options[:body][:channel] = final_channel(channel) if channel

    response = HTTParty.post(webhook_url, options)

    raise CouldNotPostError unless response.code == 200
  end

  private

  def final_channel(channel)
    return "##{channel}" unless channel.start_with?('#')

    channel
  end
end
