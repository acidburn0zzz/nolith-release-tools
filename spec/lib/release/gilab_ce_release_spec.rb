require 'spec_helper'
require 'release/gitlab_ce_release'

describe Release::GitlabCeRelease do
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
    # Cloning the CE / EE repo takes too long for tests
    allow_any_instance_of(described_class).to receive(:remotes).and_return(repo_remotes)
    allow_any_instance_of(Release::OmnibusGitLabRelease).to receive(:remotes).and_return({ gitlab: "https://gitlab.com/gitlab-org/#{ob_repo_name}.git" })
  end
  after do
    FileUtils.rm_r(repo_path, secure: true) if File.exists?(repo_path)
    FileUtils.rm_r(ob_repo_path, secure: true) if File.exists?(ob_repo_path)
  end

  { ce: '', ee: '-ee' }.each do |edition, suffix|
    describe '#execute' do
      before do
        described_class.new(version).execute
        Dir.chdir(repo_path) { `git checkout #{branch}` }
      end

      context "with an existing 9-1-stable#{suffix} stable branch, releasing a patch" do
        let(:version) { "9.1.24#{suffix}" }
        let(:ob_version) { "9.1.24+#{edition}.0" }
        let(:branch) { "9-1-stable#{suffix}" }

        describe "release GitLab#{suffix.upcase}" do
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
            expect(File.open(File.join(ob_repo_path, 'GITLAB_PAGES_VERSION')).read.strip).to eq(edition == :ee ? '4.4.4' : 'master')
          end
        end
      end

      context "with a new 10-1-stable#{suffix} stable branch, releasing a RC" do
        let(:version) { "10.1.0-rc13#{suffix}" }
        let(:ob_version) { "10.1.0+rc13.#{edition}.0" }
        let(:branch) { "10-1-stable#{suffix}" }

        describe "release GitLab #{suffix.upcase}" do
          it 'creates a new branch and updates the version in VERSION, and creates a new branch, a new tag and updates the version files in the omnibus-gitlab repo' do
            # GitLab expectations
            expect(Dir.chdir(repo_path) { `git symbolic-ref HEAD`.strip }).to eq "refs/heads/#{branch}"
            expect(File.open(File.join(repo_path, 'VERSION')).read.strip).to eq version

            # Omnibus-GitLab expectations
            expect(Dir.chdir(ob_repo_path) { `git symbolic-ref HEAD`.strip }).to eq "refs/heads/#{branch}"
            expect(Dir.chdir(ob_repo_path) { `git tag -l`.strip }).to eq ob_version
            expect(File.open(File.join(ob_repo_path, 'VERSION')).read.strip).to eq version
            expect(File.open(File.join(ob_repo_path, 'GITLAB_SHELL_VERSION')).read.strip).to eq '2.3.0'
            expect(File.open(File.join(ob_repo_path, 'GITLAB_WORKHORSE_VERSION')).read.strip).to eq '3.4.0'
            expect(File.open(File.join(ob_repo_path, 'GITLAB_PAGES_VERSION')).read.strip).to eq(edition == :ee ? '4.5.0' : 'master')
          end
        end
      end

      context "with a new 10-1-stable#{suffix} stable branch, releasing a stable .0" do
        let(:version) { "10.1.0#{suffix}" }
        let(:ob_version) { "10.1.0+#{edition}.0" }
        let(:branch) { "10-1-stable#{suffix}" }

        describe "release GitLab #{suffix.upcase}" do
          it 'creates a new branch and updates the version in VERSION, and creates a new branch, a new tag and updates the version files in the omnibus-gitlab repo' do
            # GitLab expectations
            expect(Dir.chdir(repo_path) { `git symbolic-ref HEAD`.strip }).to eq "refs/heads/#{branch}"
            expect(File.open(File.join(repo_path, 'VERSION')).read.strip).to eq version

            Dir.chdir(repo_path) { `git checkout master` }
            expect(Dir.chdir(repo_path) { `git symbolic-ref HEAD`.strip }).to eq "refs/heads/master"
            if edition == :ee
              expect(File.open(File.join(repo_path, 'VERSION')).read.strip).to eq '1.2.0'
              expect(Dir.chdir(repo_path) { `git tag -l`.strip }).to match eq 'v10.1.0-ee'
            else
              expect(File.open(File.join(repo_path, 'VERSION')).read.strip).to eq '10.2.0-pre'
              expect(Dir.chdir(repo_path) { `git describe --tag`.strip }).to match /\Av10\.2\.0\.pre/
            end

            # Omnibus-GitLab expectations
            expect(Dir.chdir(ob_repo_path) { `git symbolic-ref HEAD`.strip }).to eq "refs/heads/#{branch}"
            expect(Dir.chdir(ob_repo_path) { `git tag -l`.strip }).to eq ob_version
            expect(File.open(File.join(ob_repo_path, 'VERSION')).read.strip).to eq version
            expect(File.open(File.join(ob_repo_path, 'GITLAB_SHELL_VERSION')).read.strip).to eq '2.3.0'
            expect(File.open(File.join(ob_repo_path, 'GITLAB_WORKHORSE_VERSION')).read.strip).to eq '3.4.0'
            expect(File.open(File.join(ob_repo_path, 'GITLAB_PAGES_VERSION')).read.strip).to eq(edition == :ee ? '4.5.0' : 'master')
          end
        end
      end
    end

    context "with a version < 8.5.0" do
      let(:version) { "1.9.24-ee" }
      let(:ob_version) { "1.9.24+ee.0" }
      let(:branch) { "1-9-stable-ee" }

      describe "release GitLab-EE" do
        let!(:release) { described_class.new(version).execute }

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
          expect(File.exist?(File.join(ob_repo_path, 'GITLAB_PAGES_VERSION'))).to be_falsey
        end
      end
    end

  end
end
