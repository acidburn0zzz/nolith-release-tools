# frozen_string_literal: true

module SlackWebhookHelpers
  def expect_post(params)
    expect(HTTP).to receive(:post).with(webhook_url, params)
  end

  def response(code)
    double(code: code)
  end
end
