require 'spec_helper'

require 'slack/upstream_merge_notification'

describe Slack::UpstreamMergeNotification do
  include_context 'Slack webhook'

  let(:merge_request) do
    double(url: 'http://gitlab.com/mr',
           to_reference: '!123',
           conflicts: nil,
           created_at: Time.new(2018, 1, 4, 6))
  end

  describe '.new_merge_request' do
    it 'posts a message' do
      expect_post(body: { text: "Created a new merge request <#{merge_request.url}|#{merge_request.to_reference}>" }.to_json)
        .and_return(response)

      described_class.new_merge_request(merge_request)
    end

    it 'posts the number of conflicts in the message' do
      merge_request = double(url: 'http://gitlab.com/mr',
                             to_reference: '!123',
                             created_at: Time.new(2018, 1, 4, 6),
                             conflicts: %i[a b c])
      expect_post(body: { text: "Created a new merge request <#{merge_request.url}|#{merge_request.to_reference}> with #{merge_request.conflicts.count} conflicts! :warning:" }.to_json)
        .and_return(response)

      described_class.new_merge_request(merge_request)
    end
  end

  describe '.existing_merge_request' do
    it 'posts a message' do
      expect_post(body: { text: "Tried to create a new merge request but <#{merge_request.url}|#{merge_request.to_reference}> from 2 hours ago is still pending! :hourglass:" }.to_json)
        .and_return(response)

      described_class.existing_merge_request(merge_request)
    end
  end

  describe '.missing_merge_request' do
    it 'posts a message' do
      expect_post({ body: { text: "The latest upstream merge MR could not be created! Please have a look at <https://gitlab.com/gitlab-org/release-tools/-/jobs/#{ci_job_id}>. :boom:" }.to_json })
        .and_return(response)

      described_class.missing_merge_request
    end
  end

  describe '.downstream_is_up_to_date' do
    it 'posts a message' do
      expect_post(body: { text: "EE is already up-to-date with CE. No merge request was created. :tada:" }.to_json)
        .and_return(response)

      described_class.downstream_is_up_to_date
    end
  end

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
