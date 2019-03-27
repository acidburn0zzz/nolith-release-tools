# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Security::MergeRequestsMerger do
  describe '#execute' do
    it 'merges valid merge requests' do
      merger = described_class.new
      mr1 = double(:merge_request, target_branch: 'foo')
      mr2 = double(:merge_request, target_branch: 'bar')
      result = double(:result)

      allow(merger)
        .to receive(:validated_merge_requests)
        .and_return([mr1, mr2])

      allow(merger)
        .to receive(:merge)
        .with(mr1)
        .and_return(true)

      allow(merger)
        .to receive(:merge)
        .with(mr2)
        .and_return(false)

      allow(ReleaseTools::Security::MergeResult)
        .to receive(:from_array)
        .with([[true, mr1], [false, mr2]])
        .and_return(result)

      expect(ReleaseTools::Slack::ChatopsNotification)
        .to receive(:merged_security_merge_requests)
        .with(result)

      merger.execute
    end
  end

  describe '#validated_merge_requests' do
    let(:validator) { double(:validator) }

    before do
      allow(ReleaseTools::Security::MergeRequestsValidator)
        .to receive(:new)
        .and_return(validator)
    end

    context 'when merging to master is enabled' do
      it 'includes merge requests that target master' do
        master_mr = double(:merge_request, target_branch: 'master')
        backport = double(:merge_request, target_branch: '11-8-stable')
        merger = described_class.new(merge_master: true)

        allow(validator)
          .to receive(:execute)
          .and_return([master_mr, backport])

        expect(merger.validated_merge_requests).to eq([master_mr, backport])
      end
    end

    context 'when merging to master is not enabled' do
      it 'does not include merge requests that target master' do
        master_mr = double(:merge_request, target_branch: 'master')
        backport = double(:merge_request, target_branch: '11-8-stable')
        merger = described_class.new(merge_master: false)

        allow(validator)
          .to receive(:execute)
          .and_return([master_mr, backport])

        expect(merger.validated_merge_requests).to eq([backport])
      end
    end
  end

  describe '#merge' do
    it 'returns true when the merge request is merged' do
      mr = double(:merge_request, project_id: 1, iid: 2)
      merger = described_class.new
      response = double(:response, merge_commit_sha: '123')

      allow(merger.client)
        .to receive(:accept_merge_request)
        .with(1, 2)
        .and_return(response)

      expect(merger.merge(mr)).to eq(true)
    end

    it 'reassigns the MR when the merge commit SHA is empty' do
      mr = double(:merge_request, project_id: 1, iid: 2)
      merger = described_class.new
      response = double(:response, merge_commit_sha: nil)

      allow(merger.client)
        .to receive(:accept_merge_request)
        .with(1, 2)
        .and_return(response)

      allow(merger)
        .to receive(:reassign_merge_request)
        .with(mr)

      expect(merger.merge(mr)).to eq(false)
    end

    it 'reassigns the MR when the merge commit SHA is missing' do
      mr = double(:merge_request, project_id: 1, iid: 2)
      merger = described_class.new

      allow(merger.client)
        .to receive(:accept_merge_request)
        .with(1, 2)
        .and_return(double(:response))

      allow(merger)
        .to receive(:reassign_merge_request)
        .with(mr)

      expect(merger.merge(mr)).to eq(false)
    end
  end

  describe '#reassign_merge_request' do
    it 'reassigns the merge request and notifies the author' do
      merger = described_class.new
      mr = double(
        :merge_request,
        project_id: 1,
        iid: 2,
        author: double(:author, id: 3, username: 'alice')
      )

      allow(merger.client)
        .to receive(:create_merge_request_discussion)
        .with(1, 2, body: an_instance_of(String))

      allow(merger.client)
        .to receive(:update_merge_request)
        .with(1, 2, assignee_id: 3)

      merger.reassign_merge_request(mr)
    end
  end
end
