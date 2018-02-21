require 'spec_helper'

require 'slack/tag_notification'

describe Slack::TagNotification do
  include SlackWebhookHelpers

  let(:webhook_url) { 'https://slack.example.com/' }

  describe '.webhook_url' do
    it 'returns blank when not set' do
      ClimateControl.modify(SLACK_TAG_URL: nil) do
        expect(described_class.webhook_url).to eq('')
      end
    end

    it 'returns ENV value when set' do
      ClimateControl.modify(SLACK_TAG_URL: webhook_url) do
        expect(described_class.webhook_url).to eq(webhook_url)
      end
    end
  end

  describe '.release' do
    let(:version) { Version.new('10.4.20') }

    before do
      allow(SharedStatus).to receive(:user).and_return('Liz Lemon')
    end

    around do |ex|
      ClimateControl.modify(SLACK_TAG_URL: webhook_url) do
        ex.run
      end
    end

    it 'posts a message' do
      expect_post(body: { text: "_Liz Lemon_ tagged `10.4.20`" }.to_json)
        .and_return(response(200))

      described_class.release(version)
    end
  end
end
