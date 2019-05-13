# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::ComponentVersions do
  let(:fake_client) { spy }

  before do
    stub_const('ReleaseTools::GitlabClient', fake_client)
  end

  describe '.get' do
    it 'returns a Hash of component versions' do
      project = ReleaseTools::Project::GitlabEe
      commit_id = 'abcdefg'
      file = described_class::FILES.sample

      expect(fake_client).to receive(:file_contents)
        .with(project.path, file, commit_id)
        .and_return("1.2.3\n")

      expect(described_class.get(project, commit_id)).to match(
        a_hash_including(
          'VERSION' => commit_id,
          file => '1.2.3'
        )
      )
    end
  end

  describe '.update_omnibus' do
    let(:project) { ReleaseTools::Project::OmnibusGitlab }
    let(:version_map) do
      {
        'GITALY_SERVER_VERSION' => '1.33.0',
        'GITLAB_PAGES_VERSION' => '1.5.0',
        'GITLAB_SHELL_VERSION' => '9.0.0',
        'GITLAB_WORKHORSE_VERSION' => '8.6.0',
        'VERSION' => '0cfa69752d82b8e134bdb8e473c185bdae26ccc2'
      }
    end

    it 'commits version updates for the specified ref' do
      without_dry_run do
        described_class.update_omnibus('foo-branch', version_map)
      end

      expect(fake_client).to have_received(:create_commit).with(
        ReleaseTools::Project::OmnibusGitlab,
        'foo-branch',
        anything,
        array_including(
          action: 'update',
          file_path: '/VERSION',
          content: "#{version_map['VERSION']}\n"
        )
      )
    end

    it 'does not create a commit with a version update without changes' do
      allow(described_class).to receive(:version_changes).and_return({})

      expect(fake_client).not_to have_received(:create_commit)
      without_dry_run do
        described_class.update_omnibus('foo-branch', version_map)
      end
    end
  end

  describe '.version_changes' do
    let(:project) { ReleaseTools::Project::OmnibusGitlab }
    let(:version_map) { { 'GITALY_SERVER_VERSION' => '1.33.0' } }

    it 'keeps omnibus versions that have changed' do
      expect(fake_client).to receive(:file_contents)
        .with(project.path, "/GITALY_SERVER_VERSION", 'foo-branch')
        .and_return("1.2.3\n")

      expect(described_class.version_changes('foo-branch', version_map)).to match(
        a_hash_including(
          'GITALY_SERVER_VERSION' => '1.33.0'
        )
      )
    end

    it 'rejects omnibus versions that have not changed' do
      expect(fake_client).to receive(:file_contents)
        .with(project.path, "/GITALY_SERVER_VERSION", 'foo-branch')
        .and_return("1.33.0\n")

      expect(described_class.version_changes('foo-branch', version_map)).not_to match(
        a_hash_including(
          'GITALY_SERVER_VERSION' => '1.33.0'
        )
      )
    end
  end
end
