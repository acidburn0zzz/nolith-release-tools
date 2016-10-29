require 'spec_helper'
require 'rugged'

require 'release/gitlab_ce_release'

describe Release::GitlabCeRelease do
  include RuggedMatchers

  # NOTE (rspeicher): There is some "magic" here that can be confusing.
  #
  # The release process checks out a remote to `/tmp/some_folder`, where
  # `some_folder` is based on the last part of a remote path, excluding `.git`.
  #
  # So `https://gitlab.com/foo/bar/repository.git` gets checked out to
  # `/tmp/repository`, and `/this/project/spec/fixtures/repositories/release`
  # gets checked out to `/tmp/release`.
  let(:repo_path)    { File.join('/tmp', ReleaseFixture.repository_name) }
  let(:ob_repo_path) { File.join('/tmp', OmnibusReleaseFixture.repository_name) }

  # These two Rugged repositories are used for _verifying the result_ of the
  # release run. Not to be confused with the fixture repositories.
  let(:repository)    { Rugged::Repository.new(repo_path) }
  let(:ob_repository) { Rugged::Repository.new(ob_repo_path) }

  before do
    fixture    = ReleaseFixture.new
    ob_fixture = OmnibusReleaseFixture.new

    fixture.rebuild_fixture!
    ob_fixture.rebuild_fixture!

    # Disable cleanup so that we can see what's the state of the temp Git repos
    allow_any_instance_of(Repository).to receive(:cleanup).and_return(true)

    # Override the actual remotes with our local fixture repositories
    allow_any_instance_of(described_class).to receive(:remotes)
      .and_return({ gitlab: fixture.fixture_path })
    allow_any_instance_of(Release::OmnibusGitLabRelease).to receive(:remotes)
      .and_return({ gitlab: ob_fixture.fixture_path })
  end

  after do
    # Manually perform the cleanup we disabled in the `before` block
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
            aggregate_failures do
              # GitLab expectations
              expect(repository.head.name).to eq "refs/heads/#{branch}"
              expect(repository).to have_version.at(version)

              # Omnibus-GitLab expectations
              expect(ob_repository.head.name).to eq "refs/heads/#{branch}"
              expect(ob_repository.tags[ob_version]).not_to be_nil
              expect(ob_repository).to have_version.at(version)
              expect(ob_repository).to have_version('shell').at('2.2.2')
              expect(ob_repository).to have_version('workhorse').at('3.3.3')
              expect(ob_repository).to have_version('pages')
                .at(edition == :ee ? '4.4.4' : 'master')
            end
          end
        end
      end

      context "with a new 10-1-stable#{suffix} stable branch, releasing an RC" do
        let(:version)    { "10.1.0-rc13#{suffix}" }
        let(:ob_version) { "10.1.0+rc13.#{edition}.0" }
        let(:branch)     { "10-1-stable#{suffix}" }

        describe "release GitLab#{suffix.upcase}" do
          it 'creates a new branch and updates the version in VERSION, and creates a new branch, a new tag and updates the version files in the omnibus-gitlab repo' do
            aggregate_failures do
              # GitLab expectations
              expect(repository.head.name).to eq "refs/heads/#{branch}"
              expect(repository).to have_version.at(version)

              # Omnibus-GitLab expectations
              expect(ob_repository.head.name).to eq "refs/heads/#{branch}"
              expect(ob_repository.tags[ob_version]).not_to be_nil
              expect(ob_repository).to have_version.at(version)
              expect(ob_repository).to have_version('shell').at('2.3.0')
              expect(ob_repository).to have_version('workhorse').at('3.4.0')
              expect(ob_repository).to have_version('pages')
                .at(edition == :ee ? '4.5.0' : 'master')
            end
          end
        end
      end

      context "with a new 10-1-stable#{suffix} stable branch, releasing a stable .0" do
        let(:version)    { "10.1.0#{suffix}" }
        let(:ob_version) { "10.1.0+#{edition}.0" }
        let(:branch)     { "10-1-stable#{suffix}" }

        describe "release GitLab#{suffix.upcase}" do
          it 'creates a new branch and updates the version in VERSION, and creates a new branch, a new tag and updates the version files in the omnibus-gitlab repo' do
            aggregate_failures do
              # GitLab expectations
              expect(repository.head.name).to eq "refs/heads/#{branch}"
              expect(repository).to have_version.at(version)

              repository.checkout('master')

              if edition == :ee
                expect(repository).to have_version.at('1.2.0')
                expect(repository.tags['v10.1.0-ee']).not_to be_nil
              else
                expect(repository).to have_version.at('10.2.0-pre')
                expect(repository.tags['v10.2.0.pre']).not_to be_nil
              end

              # Omnibus-GitLab expectations
              expect(ob_repository.head.name).to eq "refs/heads/#{branch}"
              expect(ob_repository.tags[ob_version]).not_to be_nil
              expect(ob_repository).to have_version.at(version)
              expect(ob_repository).to have_version('shell').at('2.3.0')
              expect(ob_repository).to have_version('workhorse').at('3.4.0')
              expect(ob_repository).to have_version('pages')
                .at(edition == :ee ? '4.5.0' : 'master')
            end
          end
        end
      end
    end

    context "with a version < 8.5.0" do
      let(:version)    { "1.9.24-ee" }
      let(:ob_version) { "1.9.24+ee.0" }
      let(:branch)     { "1-9-stable-ee" }

      describe "release GitLab-EE" do
        before do
          described_class.new(version).execute 
          repository.checkout(branch)
        end

        it 'creates a new branch and updates the version in VERSION, and creates a new branch, a new tag and updates the version files in the omnibus-gitlab repo' do
          aggregate_failures do
            # GitLab expectations
            expect(repository.head.name).to eq "refs/heads/#{branch}"
            expect(repository).to have_version.at(version)

            # Omnibus-GitLab expectations
            expect(ob_repository.head.name).to eq "refs/heads/#{branch}"
            expect(ob_repository.tags[ob_version]).not_to be_nil
            expect(ob_repository).to have_version.at(version)
            expect(ob_repository).to have_version('shell').at('2.2.2')
            expect(ob_repository).to have_version('workhorse').at('3.3.3')
            expect(ob_repository).not_to have_version('pages')
          end
        end
      end
    end
  end
end
