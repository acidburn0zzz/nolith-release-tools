# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Release::HelmGitlabRelease, :slow do
  include RuggedMatchers

  let(:repo_path) { File.join(Dir.tmpdir, HelmReleaseFixture.repository_name) }
  let(:repository) { Rugged::Repository.new(repo_path) }

  before do
    fixture = HelmReleaseFixture.new

    fixture.rebuild_fixture!

    # Disable cleanup so that we can see what's the state of the temp Git repos
    allow_any_instance_of(ReleaseTools::RemoteRepository).to receive(:cleanup).and_return(true)

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
      allow(ReleaseTools::Changelog::Manager).to receive(:new).with(repo_path).and_return(changelog_manager)
    end

    # In the fixtures, we specified GitLab 11.0.5 going into Charts version
    # 0.2.7. So the backport release 11.0.6 becomes Charts version 0.2.8.
    # This makes sure our code to map backport GitLab releases to a Chart
    # version work.
    context "with an existing 0-2-stable stable branch, releasing a backport security patch" do
      let(:chart_version)          { nil }
      let(:expected_chart_version) { '0.2.8' }
      let(:gitlab_version)         { "11.0.6" }
      let(:branch)                 { "0-2-stable" }
      let(:release)                { described_class.new(chart_version, gitlab_version) }

      describe "release GitLab Chart" do
        let(:chart_version) { '0.2.8' }

        it_behaves_like 'helm-release #execute', expect_master: true
      end

      describe "release GitLab Chart by passing only gitlab version" do
        it_behaves_like 'helm-release #execute', expect_master: true
      end
    end

    # In the fixtures, we mimicked  Charts bumping the major version due to
    # breaking changes, and thus GitLab 11.2.0 went into Charts version 1.0.0
    # So, next patch release 11.2.1 becomes Charts version 1.0.1
    context "with an existing 1-0-stable branch, releasing a regular patch version" do
      let(:chart_version)          { nil }
      let(:expected_chart_version) { '1.0.1' }
      let(:gitlab_version)         { "11.2.1" }
      let(:branch)                 { "1-0-stable" }
      let(:release)                { described_class.new(chart_version, gitlab_version) }

      describe "release GitLab Chart" do
        let(:chart_version) { "1.0.1" }

        it_behaves_like 'helm-release #execute'
      end

      describe "release GitLab Chart by passing only gitlab version" do
        it_behaves_like 'helm-release #execute'
      end
    end

    context "with a new 1-1-stable branch, releasing a GitLab RC" do
      let(:chart_version)          { nil }
      let(:expected_chart_version) { '1.1.0' }
      let(:gitlab_version)         { "11.4.0-rc1" }
      let(:branch)                 { "1-1-stable" }
      let(:release)                { described_class.new(chart_version, gitlab_version) }

      describe "update GitLab Chart" do
        let(:chart_version) { "1.1.0" }

        it_behaves_like 'helm-release #execute', expect_tag: false, expect_master: false
      end

      describe "update GitLab Chart by passing only gitlab version" do
        it_behaves_like 'helm-release #execute', expect_tag: false, expect_master: false
      end
    end

    context "with a new 1-1-stable branch, releasing a GitLab minor version" do
      let(:chart_version)          { nil }
      let(:expected_chart_version) { '1.1.0' }
      let(:gitlab_version)         { "11.4.0" }
      let(:branch)                 { "1-1-stable" }
      let(:release)                { described_class.new(chart_version, gitlab_version) }

      describe "update GitLab Chart" do
        let(:chart_version) { "1.1.0" }

        it_behaves_like 'helm-release #execute'
      end

      describe "update GitLab Chart by passing only gitlab version" do
        it_behaves_like 'helm-release #execute'
      end
    end
  end
end
