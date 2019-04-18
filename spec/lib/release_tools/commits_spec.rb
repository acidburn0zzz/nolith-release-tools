# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Commits do
  let(:project) { ReleaseTools::Project::GitlabCe }

  before do
    # Reduce our fixture payload
    stub_const('ReleaseTools::Commits::MAX_COMMITS_TO_CHECK', 5)
  end

  describe '#latest_successful' do
    it 'returns the latest successful commit' do
      instance = described_class.new(project)

      VCR.use_cassette('commits/list') do
        commit = instance.latest_successful

        expect(commit.id).to eq 'a5f13e591f617931434d66263418a2f26abe3abe'
      end
    end
  end

  describe '#latest_dev_green_build_commit' do
    it 'handles a missing commit on dev' do
      allow(ReleaseTools::GitlabDevClient)
        .to receive(:commit)
        .and_raise(gitlab_error(:NotFound))

      instance = described_class.new(project)

      VCR.use_cassette('commits/list') do
        expect(instance.latest_dev_green_build_commit).to be_nil
      end
    end

    it 'returns a commit found on dev' do
      allow(ReleaseTools::GitlabDevClient)
        .to receive(:commit)
        .and_return('foo')

      instance = described_class.new(project)

      VCR.use_cassette('commits/list') do
        expect(instance.latest_dev_green_build_commit).not_to be_nil
      end
    end
  end
end
