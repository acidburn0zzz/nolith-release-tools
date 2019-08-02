# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Helm::VersionManager do
  include RuggedMatchers

  let(:repo_path) { File.join('/tmp', HelmReleaseFixture.repository_name) }
  let(:repository) { Rugged::Repository.new(repo_path) }
  let(:version_manager) { ReleaseTools::Release::HelmGitlabRelease.new(nil, '11.5.4').version_manager }
  let(:messages) do
    {
      'v0.2.7' => 'Version v0.2.7 - contains GitLab EE 11.0.5',
      'v1.0.0' => 'Version v1.0.0 - contains GitLab EE 11.2.0'
    }
  end

  before do
    fixture = HelmReleaseFixture.new

    fixture.rebuild_fixture!

    # Disable cleanup so that we can see what's the state of the temp Git repos
    allow_any_instance_of(ReleaseTools::RemoteRepository).to receive(:cleanup).and_return(true) # rubocop:disable RSpec/AnyInstance

    # Override the actual remotes with our local fixture repositories
    allow_any_instance_of(ReleaseTools::Release::HelmGitlabRelease).to receive(:remotes) # rubocop:disable RSpec/AnyInstance
      .and_return(gitlab: "file://#{fixture.fixture_path}")
  end

  after do
    # Manually perform the cleanup we disabled in the `before` block
    FileUtils.rm_rf(repo_path, secure: true) if File.exist?(repo_path)
  end

  describe "#get_latest_version" do
    it 'sorts versions correctly and returns latest version' do
      versions = %w[v1.7.5 v10.7.5 v9.7.5]

      expect(version_manager.get_latest_version(versions)).to eq(ReleaseTools::HelmGitlabVersion.new("10.7.5"))
    end
  end

  describe "#get_matching_tags" do
    context 'minor version' do
      it 'returns matching tags correctly' do
        expect(version_manager.get_matching_tags(messages, major: '11', minor: '0')).to eq(
          'v0.2.7' => 'Version v0.2.7 - contains GitLab EE 11.0.5'
        )
      end
    end

    context 'major version' do
      it 'returns matching tags correctly' do
        expect(version_manager.get_matching_tags(messages, major: '11')).to eq(messages)
      end
    end
  end

  describe '#next_version' do
    context 'new gitlab patch version' do
      it 'returns correct next version' do
        expect(version_manager.next_version(ReleaseTools::HelmGitlabVersion.new('11.2.1'))).to eq('1.0.1')
      end
    end

    context 'new gitlab minor version' do
      it 'returns correct next version' do
        expect(version_manager.next_version(ReleaseTools::HelmGitlabVersion.new('11.3.0'))).to eq('1.1.0')
      end
    end

    context 'new gitlab major version' do
      it 'returns correct next version' do
        expect(version_manager.next_version(ReleaseTools::HelmGitlabVersion.new('12.0.0'))).to eq('2.0.0')
      end
    end

    context 'existing version' do
      it 'shows warning' do
        expect(version_manager).to receive(:warn).with('A chart version already exists for GitLab version 11.0.5')
        expect(version_manager.next_version(ReleaseTools::HelmGitlabVersion.new('11.0.5'))).to eq('0.2.7')
      end
    end
  end
end
