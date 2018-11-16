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
    let(:message) { "_Liz Lemon_ tagged `#{version}`" }

    before do
      allow(SharedStatus).to receive(:user).and_return('Liz Lemon')
    end

    around do |ex|
      ClimateControl.modify(SLACK_TAG_URL: webhook_url) do
        ex.run
      end
    end

    context 'with a CI job URL' do
      it 'posts an attachment' do
        expect_post(body: {
          attachments: [{
            fallback: '',
            color: 'good',
            text: "<foo|#{message}>",
            mrkdwn_in: ['text']
          }]
        }.to_json).and_return(response(200))

        ClimateControl.modify(CI_JOB_URL: 'foo') do
          described_class.release(version)
        end
      end
    end

    context 'without a CI job URL' do
      around do |ex|
        # Prevent these tests from failing on CI
        ClimateControl.modify(CI_JOB_URL: nil) do
          ex.run
        end
      end

      it 'posts a message' do
        expect_post(body: { text: message }.to_json)
          .and_return(response(200))

        described_class.release(version)
      end

      it 'posts a message indicating a security release' do
        message << " as a security release"

        expect_post(body: { text: message }.to_json)
          .and_return(response(200))

        ClimateControl.modify(SECURITY: 'true') do
          described_class.release(version)
        end
      end
    end
  end
end
