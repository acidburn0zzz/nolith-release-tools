# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::PassingBuild do
  let(:project) { ReleaseTools::Project::GitlabCe }
  let(:fake_commit) { double('Commit', id: '1234') }
  let(:version_map) { { 'VERSION' => '1.2.3' } }

  subject(:service) { described_class.new(project, 'master') }

  describe '#execute' do
    let(:fake_commits) { spy }

    before do
      stub_const('ReleaseTools::Commits', fake_commits)
    end

    it 'raises an error without a dev commit' do
      expect(fake_commits).to receive(:latest_dev_green_build_commit)
        .and_return(nil)

      expect { service.execute(nil) }
        .to raise_error(/Unable to find a passing/)
    end

    it 'updates and tags Omnibus when `trigger_build` is true', :silence_stdout do
      expect(fake_commits).to receive(:latest_dev_green_build_commit)
        .and_return(fake_commit)

      expect(ReleaseTools::ComponentVersions)
        .to receive(:get).with(project, fake_commit.id)
        .and_return(version_map)

      expect(service).to receive(:update_omnibus)
        .with(version_map)
        .and_return(fake_commit)
      expect(service).to receive(:tag_omnibus)
        .with(fake_commit, version_map)

      service.execute(double(trigger_build: true))
    end
  end

  describe '#update_omnibus' do
    let(:fake_client) { spy }

    it 'updates Omnibus versions', :silence_stdout do
      expect(ReleaseTools::ComponentVersions)
        .to receive(:update_omnibus).with('master', version_map)
        .and_return(double('Commit', short_id: 'abcdefg'))

      service.update_omnibus(version_map)
    end
  end

  describe '#tag_omnibus' do
    # TODO (rspeicher): All of it!
  end
end
