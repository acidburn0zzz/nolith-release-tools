# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Slack::UpstreamMergeNotification do
  include SlackWebhookHelpers

  let(:webhook_url) { 'https://slack.example.com/' }
  let(:merge_request) do
    double(url: 'http://gitlab.com/mr',
           to_reference: '!123',
           conflicts: nil,
           created_at: Time.new(2018, 1, 4, 6))
  end

  around do |ex|
    ClimateControl.modify(SLACK_UPSTREAM_MERGE_URL: webhook_url, CI_JOB_URL: 'https://example.com') do
      Timecop.freeze(Time.new(2018, 1, 4, 8, 30, 42)) do
        ex.run
      end
    end
  end

  describe '.new_merge_request' do
    it 'posts a message' do
      expect_post(json: { text: "Created a new merge request <#{merge_request.url}|#{merge_request.to_reference}>" })
        .and_return(response(200))

      described_class.new_merge_request(merge_request)
    end

    it 'posts the number of conflicts in the message' do
      merge_request = double(url: 'http://gitlab.com/mr',
                             to_reference: '!123',
                             created_at: Time.new(2018, 1, 4, 6),
                             conflicts: %i[a b c])
      expect_post(json: { text: "Created a new merge request <#{merge_request.url}|#{merge_request.to_reference}> with #{merge_request.conflicts.count} conflicts! :warning:" })
        .and_return(response(200))

      described_class.new_merge_request(merge_request)
    end
  end

  describe '.existing_merge_request' do
    it 'posts a message' do
      expect_post(json: { text: "Tried to create a new merge request but <#{merge_request.url}|#{merge_request.to_reference}> from 2 hours ago is still pending! :hourglass:" })
        .and_return(response(200))

      described_class.existing_merge_request(merge_request)
    end
  end

  describe '.missing_merge_request' do
    it 'posts a message' do
      expect_post(json: { text: "The latest upstream merge MR could not be created! Please have a look at <https://example.com>. :boom:" })
        .and_return(response(200))

      described_class.missing_merge_request
    end
  end

  describe '.downstream_is_up_to_date' do
    it 'posts a message' do
      expect_post(json: { text: "EE is already up-to-date with CE. No merge request was created. :tada:" })
        .and_return(response(200))

      described_class.downstream_is_up_to_date
    end
  end
end
