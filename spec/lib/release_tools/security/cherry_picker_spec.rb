# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Security::CherryPicker do
  let(:client) { spy }
  let(:merge_result) do
    [
      double(project_id: 1, merge_commit_sha: 'a').as_null_object,
      double(project_id: 1, merge_commit_sha: 'b').as_null_object,
      double(project_id: 2, merge_commit_sha: 'c').as_null_object,
      double(project_id: 3, merge_commit_sha: 'd').as_null_object,
      double(project_id: 4, merge_commit_sha: 'e').as_null_object
    ]
  end

  before do
    enable_feature(:security_cherry_picker)

    stub_const('ReleaseTools::Security::Client', client)

    allow(ReleaseTools::AutoDeployBranch).to receive(:current)
      .and_return('X-Y-auto-deploy-YYYYMMDD')

    # Odd-numbered projects have no auto-deploy branch
    allow(client).to receive(:branch) do |project_id, _|
      if project_id.odd? # rubocop:disable Style/GuardClause
        raise gitlab_error(:NotFound, code: 404)
      else
        double('MergeRequest').as_null_object
      end
    end
  end

  describe '#execute' do
    it 'cherry-picks merge requests in projects with auto-deploy branches', :aggregate_failures do
      picker = described_class.new(merge_result)

      picks, skipped = merge_result.partition { |mr| mr.project_id.even? }

      picks.each do |mr|
        expect(client).to receive(:cherry_pick_commit).with(
          mr.project_id,
          mr.merge_commit_sha,
          ::ReleaseTools::AutoDeployBranch.current
        )
      end

      skipped.each do |mr|
        expect(client).not_to receive(:cherry_pick_commit)
          .with(mr.project_id, anything, anything)
      end

      picker.execute
    end

    it 'handles failed cherry-picks' do
      expect(client).to receive(:cherry_pick_commit)
        .and_raise(gitlab_error(:BadRequest, code: 400))

      picker = described_class.new(merge_result)

      expect { picker.execute }.not_to raise_error
    end
  end
end
