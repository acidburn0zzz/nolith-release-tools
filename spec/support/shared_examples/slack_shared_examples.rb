module SlackWebhookHelpers
  def expect_post(params)
    expect(HTTParty).to receive(:post).with(webhook_url, params)
  end

  def response(code)
    double(code: code)
  end
end
