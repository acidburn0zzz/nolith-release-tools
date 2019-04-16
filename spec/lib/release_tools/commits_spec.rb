# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Commits do
  let(:project) { ReleaseTools::Project::GitlabCe }

  # Simulate an error class from the `gitlab` gem
  def api_error(klass, message)
    error = double(parsed_response: double(message: message)).as_null_object

    klass.new(error)
  end

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
      expect(ReleaseTools::GitlabDevClient)
        .to receive(:commit)
        .and_raise(api_error(Gitlab::Error::NotFound, 'foo'))

      instance = described_class.new(project)

      VCR.use_cassette('commits/list') do
        expect { instance.latest_dev_green_build_commit }.not_to raise_error
      end
    end

    it 'returns a commit found on dev' do
      allow(ReleaseTools::GitlabDevClient)
        .to receive(:commit)
        .and_return('foo')

      instance = described_class.new(project)

      VCR.use_cassette('commits/list') do
        expect(instance.latest_dev_green_build_commit).to eq 'foo'
      end
    end
  end
end
