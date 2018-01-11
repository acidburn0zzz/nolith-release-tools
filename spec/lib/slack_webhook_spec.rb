require 'spec_helper'

require 'slack_webhook'

describe SlackWebhook do
  CI_SLACK_WEBHOOK_URL = 'http://foo.slack.com'.freeze
  CI_JOB_ID = '42'.freeze

  let(:channel) { '#ce-to-ee' }
  let(:text) { 'Hello!' }
  let(:response_class) { Struct.new(:code) }
  let(:response) { response_class.new(200) }
  let(:merge_request) { double(url: 'http://gitlab.com/mr', created_at: Time.new(2018, 1, 4, 6).to_s) }

  around do |ex|
    ClimateControl.modify CI_SLACK_WEBHOOK_URL: CI_SLACK_WEBHOOK_URL, CI_JOB_ID: CI_JOB_ID do
      Timecop.freeze(Time.new(2018, 1, 4, 8, 30, 42)) do
        ex.run
      end
    end
  end

  describe '.new_merge_request' do
    it 'posts a message' do
      expect(HTTParty)
        .to receive(:post)
          .with(
            CI_SLACK_WEBHOOK_URL,
            { body: { text: "A new merge request has been created: <#{merge_request.url}>" } })
          .and_return(response)

      described_class.new_merge_request(merge_request)
    end
  end

  describe '.existing_merge_request' do
    it 'posts a message' do
      expect(HTTParty)
        .to receive(:post)
          .with(
            CI_SLACK_WEBHOOK_URL,
            { body: { text: "Tried to create a new merge request but <#{merge_request.url}|this one> from 2 hours ago is still pending!" } })
          .and_return(response)

      described_class.existing_merge_request(merge_request)
    end
  end

  describe '.missing_merge_request' do
    it 'posts a message' do
      expect(HTTParty)
        .to receive(:post)
          .with(
            CI_SLACK_WEBHOOK_URL,
            { body: { text: "The latest upstream merge MR could not be created! Please have a look at https://gitlab.com/gitlab-org/release-tools/-/jobs/#{CI_JOB_ID}." } })
          .and_return(response)

      described_class.missing_merge_request(merge_request)
    end
  end

  describe '#fire_hook' do
    context 'when channel is not given' do
      before do
        expect(HTTParty)
          .to receive(:post)
            .with(
              CI_SLACK_WEBHOOK_URL,
              { body: { text: text } })
            .and_return(response)
      end

      it 'posts to the given url with the given arguments' do
        subject.fire_hook(text: text)
      end

      context 'when response is not successfull' do
        let(:response) { response_class.new(400) }

        it 'prepends the channel with #' do
          expect do
            subject.fire_hook(text: text)
          end.to raise_error(described_class::CouldNotPostError)
        end
      end
    end

    context 'when channel is given' do
      before do
        expect(HTTParty)
          .to receive(:post)
            .with(
              CI_SLACK_WEBHOOK_URL,
              { body: { channel: channel, text: text } })
            .and_return(response)
      end

      it 'passes the given channel' do
        subject.fire_hook(channel: channel, text: text)
      end
    end
  end
end
