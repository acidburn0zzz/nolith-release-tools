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

    it 'fetches component versions', :silence_stdout do
      expect(fake_commits).to receive(:latest_dev_green_build_commit)
        .and_return(fake_commit)

      expect(ReleaseTools::ComponentVersions)
        .to receive(:get).with(project, fake_commit.id)
        .and_return(version_map)

      expect(service).not_to receive(:trigger_build)

      service.execute(double(trigger_build: false))
    end

    it 'triggers a build when specified', :silence_stdout do
      expect(fake_commits).to receive(:latest_dev_green_build_commit)
        .and_return(fake_commit)

      expect(ReleaseTools::ComponentVersions)
        .to receive(:get).with(project, fake_commit.id)
        .and_return(version_map)

      expect(service).to receive(:trigger_build).with(version_map)

      service.execute(double(trigger_build: true))
    end
  end

  describe '#trigger_build' do
    describe 'when using auto-deploy' do
      let(:fake_client) { spy }
      let(:project) { ReleaseTools::Project::GitlabCe }
      let(:version_map) { { 'VERSION' => '1.2.3' } }

      subject(:service) { described_class.new(project, '11-10-auto-deploy-1234') }

      it 'updates Omnibus versions', :silence_stdout do
        expect(ReleaseTools::ComponentVersions)
          .to receive(:update_omnibus).with('11-10-auto-deploy-1234', version_map)
          .and_return(double('Commit', short_id: 'abcdefg'))

        service.trigger_build(version_map)
      end
    end

    describe 'when not using auto-deploy' do
      let(:fake_client) { spy }
      let(:project) { ReleaseTools::Project::GitlabCe }
      let(:version_map) { { 'VERSION' => '1.2.3' } }
      let(:pipeline_id) { ENV.fetch('CI_PIPELINE_ID', 'pipeline_id_unset') }

      subject(:service) { described_class.new(project, 'master') }

      it 'triggers a pipeline build', :silence_stdout do
        expect(ReleaseTools::GitlabDevClient)
          .to receive(:create_branch).with("master-#{pipeline_id}", 'master', project)

        allow(ReleaseTools::Pipeline).to receive(:new).and_call_original
        expect(ReleaseTools::Pipeline)
          .to receive(:new).with(project, 'master', version_map)

        expect(ReleaseTools::GitlabDevClient)
          .to receive(:delete_branch).with("master-#{pipeline_id}", project)

        VCR.use_cassette('pipeline/trigger') do
          service.trigger_build(version_map)
        end
      end
    end
  end
end
