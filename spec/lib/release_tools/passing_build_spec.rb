# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::PassingBuild do
  let(:project) { ReleaseTools::Project::GitlabCe }
  let(:fake_commit) { double('Commit', id: '1234') }

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

    it 'fetches component versions', :silence_stdout do
      expect(fake_commits).to receive(:latest_dev_green_build_commit)
        .and_return(fake_commit)

      expect(ReleaseTools::ComponentVersions)
        .to receive(:get).with(project, fake_commit)
        .and_return({})

      expect(service).not_to receive(:trigger_build)

      service.execute(double(trigger_build: false))
    end

    it 'triggers a build when specified', :silence_stdout do
      expect(fake_commits).to receive(:latest_dev_green_build_commit)
        .and_return(fake_commit)

      expect(ReleaseTools::ComponentVersions)
        .to receive(:get).with(project, fake_commit)
        .and_return({})

      expect(service).to receive(:trigger_build).with(fake_commit, {})

      service.execute(double(trigger_build: true))
    end
  end

  describe '#trigger_build', :silence_stdout do
    let(:fake_client) { spy }
    let(:fake_pipeline) { spy }

    before do
      # Ensure we don't actually perform branch creation or deletion
      allow(service).to receive(:dev_client).and_return(fake_client)

      stub_const('ReleaseTools::Pipeline', fake_pipeline)
    end

    it 'creates a temporary branch' do
      ClimateControl.modify(CI_PIPELINE_IID: 'fake_pipeline_id') do
        service.trigger_build(fake_commit, spy)
      end

      expect(fake_client).to have_received(:create_branch)
        .with('nightly-fake_pipeline_id', fake_commit.id, project)
    end

    it 'triggers a pipeline' do
      versions = { foo: 'foo', bar: 'bar' }

      service.trigger_build(fake_commit, versions)

      expect(fake_pipeline).to have_received(:new)
        .with(project, fake_commit.id, versions)
      expect(fake_pipeline).to have_received(:trigger)
    end

    it 'deletes the temporary branch' do
      ClimateControl.modify(CI_PIPELINE_IID: 'fake_pipeline_id') do
        service.trigger_build(fake_commit, spy)
      end

      expect(fake_client).to have_received(:delete_branch)
        .with('nightly-fake_pipeline_id', project)
    end
  end
end
