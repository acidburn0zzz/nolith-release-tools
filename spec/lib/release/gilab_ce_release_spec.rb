require 'spec_helper'
require 'rugged'

require 'release/gitlab_ce_release'

describe Release::GitlabCeRelease do
  let(:repo_name)  { 'release-tools-test-gitlab' }
  let(:repo_path)  { File.join('/tmp', repo_name) }
  let(:repository) { Rugged::Repository.new(repo_path) }

  let(:ob_repo_name)  { 'release-tools-test-omnibus-gitlab' }
  let(:ob_repo_path)  { File.join('/tmp', ob_repo_name) }
  let(:ob_repository) { Rugged::Repository.new(ob_repo_path) }

  before do
    # Disable cleanup so that we can see what's the state of the temp Git repos
    allow_any_instance_of(Repository).to receive(:cleanup).and_return(true)

    # Cloning the CE / EE repo takes too long for tests
    allow_any_instance_of(described_class).to receive(:remotes)
      .and_return({ gitlab: "https://gitlab.com/gitlab-org/#{repo_name}.git" })
    allow_any_instance_of(Release::OmnibusGitLabRelease).to receive(:remotes)
      .and_return({ gitlab: "https://gitlab.com/gitlab-org/#{ob_repo_name}.git" })
  end

  after do
    FileUtils.rm_r(repo_path,    secure: true) if File.exists?(repo_path)
    FileUtils.rm_r(ob_repo_path, secure: true) if File.exists?(ob_repo_path)
  end

  { ce: '', ee: '-ee' }.each do |edition, suffix|
    describe '#execute' do
      before do
        described_class.new(version).execute
        repository.checkout(branch)
      end

      context "with an existing 9-1-stable#{suffix} stable branch, releasing a patch" do
        let(:version)    { "9.1.24#{suffix}" }
        let(:ob_version) { "9.1.24+#{edition}.0" }
        let(:branch)     { "9-1-stable#{suffix}" }

        describe "release GitLab#{suffix.upcase}" do
          it 'creates a new branch and updates the version in VERSION, and creates a new branch, a new tag and updates the version files in the omnibus-gitlab repo' do
            # GitLab expectations
            expect(repository.head.name).to eq "refs/heads/#{branch}"
            expect(read_head_blob(repository, 'VERSION')).to eq version

            # Omnibus-GitLab expectations
            expect(ob_repository.head.name).to eq "refs/heads/#{branch}"
            expect(ob_repository.tags[ob_version]).not_to be_nil
            expect(read_head_blob(ob_repository, 'VERSION')).to eq version
            expect(read_head_blob(ob_repository, 'GITLAB_SHELL_VERSION')).to eq '2.2.2'
            expect(read_head_blob(ob_repository, 'GITLAB_WORKHORSE_VERSION')).to eq '3.3.3'
            expect(read_head_blob(ob_repository, 'GITLAB_PAGES_VERSION')).to eq(edition == :ee ? '4.4.4' : 'master')
          end
        end
      end

      context "with a new 10-1-stable#{suffix} stable branch, releasing a RC" do
        let(:version)    { "10.1.0-rc13#{suffix}" }
        let(:ob_version) { "10.1.0+rc13.#{edition}.0" }
        let(:branch)     { "10-1-stable#{suffix}" }

        describe "release GitLab#{suffix.upcase}" do
          it 'creates a new branch and updates the version in VERSION, and creates a new branch, a new tag and updates the version files in the omnibus-gitlab repo' do
            # GitLab expectations
            expect(repository.head.name).to eq "refs/heads/#{branch}"
            expect(read_head_blob(repository, 'VERSION')).to eq version

            # Omnibus-GitLab expectations
            expect(ob_repository.head.name).to eq "refs/heads/#{branch}"
            expect(ob_repository.tags[ob_version]).not_to be_nil
            expect(read_head_blob(ob_repository, 'VERSION')).to eq version
            expect(read_head_blob(ob_repository, 'GITLAB_SHELL_VERSION')).to eq '2.3.0'
            expect(read_head_blob(ob_repository, 'GITLAB_WORKHORSE_VERSION')).to eq '3.4.0'
            expect(read_head_blob(ob_repository, 'GITLAB_PAGES_VERSION')).to eq(edition == :ee ? '4.5.0' : 'master')
          end
        end
      end

      context "with a new 10-1-stable#{suffix} stable branch, releasing a stable .0" do
        let(:version)    { "10.1.0#{suffix}" }
        let(:ob_version) { "10.1.0+#{edition}.0" }
        let(:branch)     { "10-1-stable#{suffix}" }

        describe "release GitLab #{suffix.upcase}" do
          it 'creates a new branch and updates the version in VERSION, and creates a new branch, a new tag and updates the version files in the omnibus-gitlab repo' do
            # GitLab expectations
            expect(repository.head.name).to eq "refs/heads/#{branch}"
            expect(read_head_blob(repository, 'VERSION')).to eq version

            repository.checkout('master')

            if edition == :ee
              expect(read_head_blob(repository, 'VERSION')).to eq '1.2.0'
              expect(repository.tags['v10.1.0-ee']).not_to be_nil
            else
              expect(read_head_blob(repository, 'VERSION')).to eq '10.2.0-pre'
              expect(repository.tags['v10.2.0.pre']).not_to be_nil
            end

            # Omnibus-GitLab expectations
            expect(ob_repository.head.name).to eq "refs/heads/#{branch}"
            expect(ob_repository.tags[ob_version]).not_to be_nil
            expect(read_head_blob(ob_repository, 'VERSION')).to eq version
            expect(read_head_blob(ob_repository, 'GITLAB_SHELL_VERSION')).to eq '2.3.0'
            expect(read_head_blob(ob_repository, 'GITLAB_WORKHORSE_VERSION')).to eq '3.4.0'
            expect(read_head_blob(ob_repository, 'GITLAB_PAGES_VERSION')).to eq(edition == :ee ? '4.5.0' : 'master')
          end
        end
      end
    end

    context "with a version < 8.5.0" do
      let(:version)    { "1.9.24-ee" }
      let(:ob_version) { "1.9.24+ee.0" }
      let(:branch)     { "1-9-stable-ee" }

      describe "release GitLab-EE" do
        let!(:release) { described_class.new(version).execute }

        it 'creates a new branch and updates the version in VERSION, and creates a new branch, a new tag and updates the version files in the omnibus-gitlab repo' do
          # GitLab expectations
          expect(repository.head.name).to eq "refs/heads/#{branch}"
          expect(read_head_blob(repository, 'VERSION')).to eq version

          # Omnibus-GitLab expectations
          expect(ob_repository.head.name).to eq "refs/heads/#{branch}"
          expect(ob_repository.tags[ob_version]).not_to be_nil
          expect(read_head_blob(ob_repository, 'VERSION')).to eq version
          expect(read_head_blob(ob_repository, 'GITLAB_SHELL_VERSION')).to eq '2.2.2'
          expect(read_head_blob(ob_repository, 'GITLAB_WORKHORSE_VERSION')).to eq '3.3.3'
          expect { read_head_blob(ob_repository, 'GITLAB_PAGES_VERSION') }
            .to raise_error(Rugged::Error)
        end
      end
    end

    # Read a blob at `path` from a repository's current HEAD
    #
    # repository - Rugged::Repository object
    # path       - Path String
    #
    # Returns a stripped String
    def read_head_blob(repository, path)
      head = repository.head

      repository
        .blob_at(head.target_id, path)
        .content
        .strip
    rescue NoMethodError
      raise Rugged::Error.new("Blob at #{path} not found for #{head.target_id}")
    end
  end
end
