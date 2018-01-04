require 'spec_helper'

require 'slack_webhook'

describe SlackWebhook do
  let(:webhook_url) { 'http://foo.com' }
  let(:channel) { '#ce-to-ee' }
  let(:text) { 'Hello!' }
  let(:response_class) { Struct.new(:code) }
  let(:response) { response_class.new(200) }

  subject { described_class.new(webhook_url) }

  describe '#fire_hook' do
    context 'when channel is not given' do
      before do
        expect(HTTParty)
          .to receive(:post)
            .with(
              webhook_url,
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
              webhook_url,
              { body: { channel: channel, text: text } })
            .and_return(response)
      end

      it 'passes the given channel' do
        subject.fire_hook(channel: channel, text: text)
      end

      context 'when channel does not start with #' do
        it 'prepends the channel with #' do
          subject.fire_hook(channel: channel[1..-1], text: text)
        end
      end
    end
  end
end
