require 'spec_helper'
require 'rugged'

require 'release/helm_gitlab_release'

describe Release::HelmGitlabRelease, :silence_stdout do
  include RuggedMatchers

  let(:repo_path) { File.join('/tmp', HelmReleaseFixture.repository_name) }
  let(:repository) { Rugged::Repository.new(repo_path) }

  before do
    fixture = HelmReleaseFixture.new

    fixture.rebuild_fixture!

    # Disable cleanup so that we can see what's the state of the temp Git repos
    allow_any_instance_of(RemoteRepository).to receive(:cleanup).and_return(true)

    # Override the actual remotes with our local fixture repositories
    allow_any_instance_of(described_class).to receive(:remotes)
      .and_return({ gitlab: "file://#{fixture.fixture_path}" })
  end

  after do
    # Manually perform the cleanup we disabled in the `before` block
    FileUtils.rm_rf(repo_path, secure: true) if File.exist?(repo_path)
  end

  describe '#execute' do
    let(:changelog_manager) { double(release: true) }

    before do
      allow(Changelog::Manager).to receive(:new).with(repo_path).and_return(changelog_manager)
    end

    context "with an existing 0-2-stable stable branch, releasing a patch" do
      let(:chart_version)          { nil }
      let(:expected_chart_version) { '0.2.1' }
      let(:gitlab_version)         { "11.1.1" }
      let(:branch)                 { "0-2-stable" }
      let(:release)                { described_class.new(chart_version, gitlab_version) }

      describe "release GitLab Chart" do
        let(:chart_version) { "0.2.1" }

        it_behaves_like 'helm-release #execute'
      end

      describe "release GitLab Chart by passing only gitlab version" do
        it_behaves_like 'helm-release #execute'
      end
    end

    context "with a new 0-3-stable stable branch, updating to a GitLab RC" do
      let(:chart_version)          { nil }
      let(:expected_chart_version) { '0.3.0' }
      let(:gitlab_version)         { "11.2.0-rc1" }
      let(:branch)                 { "0-3-stable" }
      let(:release)                { described_class.new(chart_version, gitlab_version) }

      describe "update GitLab Chart" do
        let(:chart_version) { "0.3.0" }

        it_behaves_like 'helm-release #execute', expect_tag: false, expect_master: false
      end

      describe "update GitLab Chart by passing only gitlab version" do
        it_behaves_like 'helm-release #execute', expect_tag: false, expect_master: false
      end
    end

    context "with a new 0-3-stable stable branch, releasing a stable .0" do
      let(:chart_version)          { nil }
      let(:expected_chart_version) { '0.3.0' }
      let(:gitlab_version)         { "11.2.0" }
      let(:branch)                 { "0-3-stable" }
      let(:release)                { described_class.new(chart_version, gitlab_version) }

      describe "update GitLab Chart" do
        let(:chart_version) { "0.3.0" }

        it_behaves_like 'helm-release #execute'
      end

      describe "update GitLab Chart by passing only gitlab version" do
        it_behaves_like 'helm-release #execute'
      end
    end
  end
end
