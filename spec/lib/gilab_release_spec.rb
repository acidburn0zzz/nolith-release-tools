require 'spec_helper'
require 'gitlab_release'
require 'remotes'

describe GitlabRelease do
  let(:repo_name) { 'release-tools-test-gitlab' }
  let(:repo_url) { "https://gitlab.com/gitlab-org/#{repo_name}.git" }
  let(:repo_remotes) do
    { gitlab: repo_url }
  end
  let(:repo_path) { File.join('/tmp', repo_name) }
  let(:ob_repo_name) { 'release-tools-test-omnibus-gitlab' }
  let(:ob_repo_path) { File.join('/tmp', ob_repo_name) }

  before do
    # Disable cleanup so that we can see what's the state of the temp Git repos
    allow_any_instance_of(Repository).to receive(:cleanup).and_return(true)
    expect(Remotes).to receive(:omnibus_gitlab_remotes).and_return({ gitlab: "https://gitlab.com/gitlab-org/#{ob_repo_name}.git" })
  end
  after do
    FileUtils.rm_r(repo_path, secure: true) if File.exists?(repo_path)
    FileUtils.rm_r(ob_repo_path, secure: true) if File.exists?(ob_repo_path)
  end

  describe '#execute' do
    { ce: '', ee: '-ee' }.each do |edition, suffix|
      context "with an existing 1-9-stable#{suffix} stable branch" do
        let(:version) { "1.9.24#{suffix}" }
        let(:ob_version) { "1.9.24+#{suffix == '' ? 'ce' : suffix.sub('-', '')}.0" }
        let(:branch) { "1-9-stable#{suffix}" }

        describe "release GitLab#{suffix.upcase}" do
          let!(:release) { GitlabRelease.new(version, repo_remotes).execute }

          it 'creates a new branch and updates the version in VERSION, and creates a new branch, a new tag and updates the version files in the omnibus-gitlab repo' do
            # GitLab expectations
            expect(Dir.chdir(repo_path) { `git symbolic-ref HEAD`.strip }).to eq "refs/heads/#{branch}"
            expect(File.open(File.join(repo_path, 'VERSION')).read.strip).to eq version

            # Omnibus-GitLab expectations
            expect(Dir.chdir(ob_repo_path) { `git symbolic-ref HEAD`.strip }).to eq "refs/heads/#{branch}"
            expect(Dir.chdir(ob_repo_path) { `git tag -l`.strip }).to eq ob_version
            expect(File.open(File.join(ob_repo_path, 'VERSION')).read.strip).to eq version
            expect(File.open(File.join(ob_repo_path, 'GITLAB_SHELL_VERSION')).read.strip).to eq '2.2.2'
            expect(File.open(File.join(ob_repo_path, 'GITLAB_WORKHORSE_VERSION')).read.strip).to eq '3.3.3'
            expect(File.open(File.join(ob_repo_path, 'GITLAB_PAGES_VERSION')).read.strip).to eq(suffix == '-ee' ? '4.4.4' : 'master')
          end
        end
      end

      context "with a new 1-10-stable#{suffix} stable branch" do
        let(:version) { "1.10.0-rc13#{suffix}" }
        let(:ob_version) { "1.10.0+rc13.#{suffix == '' ? 'ce' : suffix.sub('-', '')}.0" }
        let(:branch) { "1-10-stable#{suffix}" }

        describe "release GitLab #{suffix.upcase}" do
          before { GitlabRelease.new(version, repo_remotes).execute }

          it 'creates a new branch and updates the version in VERSION, and creates a new branch, a new tag and updates the version files in the omnibus-gitlab repo' do
            expect(Dir.chdir(repo_path) { `git symbolic-ref HEAD`.strip }).to eq "refs/heads/#{branch}"
            expect(File.open(File.join(repo_path, 'VERSION')).read.strip).to eq version

            expect(Dir.chdir(ob_repo_path) { `git symbolic-ref HEAD`.strip }).to eq "refs/heads/#{branch}"
            expect(Dir.chdir(ob_repo_path) { `git tag -l`.strip }).to eq ob_version
            expect(File.open(File.join(ob_repo_path, 'VERSION')).read.strip).to eq version
            expect(File.open(File.join(ob_repo_path, 'GITLAB_SHELL_VERSION')).read.strip).to eq '2.3.0'
            expect(File.open(File.join(ob_repo_path, 'GITLAB_WORKHORSE_VERSION')).read.strip).to eq '3.4.0'
            expect(File.open(File.join(ob_repo_path, 'GITLAB_PAGES_VERSION')).read.strip).to eq(suffix == '-ee' ? '4.5.0' : 'master')
          end
        end
      end
    end
  end
end
