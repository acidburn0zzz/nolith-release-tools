require 'spec_helper'

require 'slack/webhook'

describe Slack::Webhook do
  include_context 'Slack webhook'

  describe '#fire_hook' do
    let(:text) { 'Hello!' }

    context 'when channel is not given' do
      before do
        expect_post(body: { text: text }.to_json)
          .and_return(response)
      end

      it 'posts to the given url with the given arguments' do
        subject.fire_hook(text: text)
      end

      context 'when response is not successfull' do
        let(:response) { response_class.new(400) }

        it 'raises CouldNotPostError' do
          expect { subject.fire_hook(text: text) }
            .to raise_error(described_class::CouldNotPostError)
        end
      end
    end

    context 'when channel is given' do
      it 'passes the given channel' do
        channel = '#ce-to-ee'

        expect_post(body: { text: text, channel: channel }.to_json)
          .and_return(response)

        subject.fire_hook(channel: channel, text: text)
      end
    end
  end
end
