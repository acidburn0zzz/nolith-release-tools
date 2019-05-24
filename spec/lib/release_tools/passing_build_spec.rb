# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::PassingBuild do
  let(:project) { ReleaseTools::Project::GitlabCe }
  let(:fake_commit) { double('Commit', id: SecureRandom.hex(20), created_at: Time.now.to_s) }
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
    let(:fake_client) { spy }
    let(:fake_ops_client) { spy }
    let(:project) { ReleaseTools::Project::GitlabCe }
    let(:version_map) { { 'VERSION' => '1.2.3' } }

    context 'when using auto-deploy' do
      let(:tag_name) { 'tag-name' }

      subject(:service) { described_class.new(project, '11-10-auto-deploy-1234') }

      before do
        allow(ReleaseTools::AutoDeploy::Naming).to receive(:tag)
          .and_return(tag_name)

        stub_const('ReleaseTools::GitlabClient', fake_client)
        stub_const('ReleaseTools::GitlabOpsClient', fake_ops_client)
      end

      it 'updates Omnibus versions', :silence_stdout do
        expect(ReleaseTools::ComponentVersions)
          .to receive(:update_omnibus).with('11-10-auto-deploy-1234', version_map)
          .and_return(fake_commit)

        expect(service).to receive(:tag_omnibus)
        expect(service).to receive(:tag_deployer)

        service.trigger_build(version_map)
      end

      it 'tags Omnibus with an annotated tag', :silence_stdout do
        expect(service).to receive(:update_omnibus)
          .and_return(fake_commit)
        expect(service).to receive(:tag_omnibus)
          .with(tag_name, anything, fake_commit)
          .and_call_original

        service.trigger_build(version_map)

        expect(fake_client)
          .to have_received(:create_tag)
          .with(
            ReleaseTools::Project::OmnibusGitlab,
            tag_name,
            fake_commit.id,
            "Auto-deploy tag-name\n\nVERSION: 1.2.3"
          )
      end

      it 'tags Deployer with an annotated tag', :silence_stdout do
        expect(service).to receive(:update_omnibus)
          .and_return(fake_commit)
        expect(service).to receive(:tag_deployer)
          .with(tag_name, anything, "master")
          .and_call_original

        service.trigger_build(version_map)

        expect(fake_ops_client)
          .to have_received(:create_tag)
          .with(
            ReleaseTools::Project::Deployer,
            tag_name,
            "master",
            "Auto-deploy tag-name\n\nVERSION: 1.2.3"
          )
      end
    end

    context 'when not using auto-deploy' do
      subject(:service) { described_class.new(project, 'master') }

      it 'triggers a pipeline build', :silence_stdout do
        ClimateControl.modify(CI_PIPELINE_ID: '1234', OMNIBUS_BUILD_TRIGGER_TOKEN: 'token') do
          expect(ReleaseTools::GitlabDevClient)
            .to receive(:create_branch).with("master-1234", 'master', project)
          expect(ReleaseTools::Pipeline)
            .to receive(:new).with(project, 'master', version_map)
            .and_return(double(trigger: true))
          expect(ReleaseTools::GitlabDevClient)
            .to receive(:delete_branch).with("master-1234", project)

          VCR.use_cassette('pipeline/trigger') do
            service.trigger_build(version_map)
          end
        end
      end
    end
  end
end
