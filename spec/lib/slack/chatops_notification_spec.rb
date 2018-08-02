
require 'spec_helper'

require 'slack/chatops_notification'

describe Slack::ChatopsNotification do
  include SlackWebhookHelpers

  let(:webhook_url) { 'https://slack.example.com/' }

  describe '.webhook_url' do
    it 'returns ENV value when set' do
      ClimateControl.modify(SLACK_CHATOPS_URL: webhook_url) do
        expect(described_class.webhook_url).to eq(webhook_url)
      end
    end
  end

  describe '.release_issue' do
    around do |ex|
      env = {
        CI_JOB_URL: 'ci.example.com',
        SLACK_CHATOPS_URL: webhook_url,
        TASK: 'release_issue',
      }

      ClimateControl.modify(env) { ex.run }
    end

    context 'outside of ChatOps' do
      around do |ex|
        ClimateControl.modify(TASK: nil) { ex.run }
      end

      it 'does nothing' do
        expect(described_class).not_to receive(:fire_hook)

        described_class.release_issue(spy)
      end
    end

    context 'with a new issue' do
      it 'posts a success message' do
        issue = double(status: :created, title: 'Title', url: 'example.com')

        expect_post(body: {
          text: 'The `release_issue` command at ci.example.com completed!',
          channel: described_class::DEFAULT_CHANNEL,
          attachments: [{
            fallback: '',
            color: 'success',
            title: 'Title',
            title_link: 'example.com'
          }]
        }.to_json).and_return(response(200))

        described_class.release_issue(issue)
      end
    end

    context 'with a pre-existing issue' do
      it 'posts a warning message' do
        issue = double(status: :persisted, title: 'Title', url: 'example.com')

        expect_post(body: {
          text: 'The `release_issue` command at ci.example.com completed!',
          channel: described_class::DEFAULT_CHANNEL,
          attachments: [{
            fallback: '',
            color: 'warning',
            title: 'Title',
            title_link: 'example.com'
          }]
        }.to_json).and_return(response(200))

        described_class.release_issue(issue)
      end
    end
  end
end
