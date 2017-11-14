require 'spec_helper'

require 'upstream_merge'

describe UpstreamMerge, :silence_stdout, :aggregate_failures do
  include RuggedMatchers

  let(:ee_repo_name) { 'gitlab-ee-upstream-merge' }
  let(:ce_repo_name) { 'gitlab-ce-upstream-merge' }
  let(:ee_fixture) { ConflictualFixture.new(File.expand_path("../fixtures/repositories/#{ee_repo_name}", __dir__)) }
  let(:ce_fixture) { ConflictualFixture.new(File.expand_path("../fixtures/repositories/#{ce_repo_name}", __dir__)) }
  let(:ee_repo_url) { "file://#{ee_fixture.fixture_path}" }
  let(:ce_repo_url) { "file://#{ce_fixture.fixture_path}" }
  let(:default_options) do
    {
      origin: ee_repo_url,
      upstream: ce_repo_url,
      merge_branch: "ce-to-ee-#{SecureRandom.hex}"
    }
  end
  let(:current_git_author_name) { 'Your Name' }
  let(:current_git_author) { { name: current_git_author_name, email: 'author@example.org' } }

  subject { described_class.new(default_options) }

  before do
    ee_fixture.rebuild_fixture!(author: current_git_author)
    ce_fixture.rebuild_fixture!(author: current_git_author)

    # Disable cleanup so that we can see what's the state of the temp Git repos
    # allow_any_instance_of(RemoteRepository).to receive(:cleanup).and_return(true)
    allow(subject).to receive(:after_upstream_merge).and_return(true)
  end

  after do
    # Manually perform the cleanup we disabled in the `before` block
    allow(subject).to receive(:after_upstream_merge).and_call_original
    subject.__send__(:after_upstream_merge)
  end

  describe '#execute' do
    let(:repository) { subject.__send__(:repository) }
    let(:ee_rugged_repo) { Rugged::Repository.new(repository.path) }

    before do
      ce_fixture.unique_update_to_file!('CONTRIBUTING.md', author: current_git_author)
      ee_fixture.unique_update_to_file!('README.md', author: current_git_author)
    end

    context 'when no conflict is detected' do
      it 'creates a branch and merges upstream/master into it' do
        subject.execute

        expect(ee_rugged_repo).to have_head(default_options[:merge_branch])
        expect(File.read(File.join(repository.path, 'CONTRIBUTING.md'))).to match(/\AContent of CONTRIBUTING\.md in #{ce_fixture.fixture_path} is \h+\z/)
        expect(File.read(File.join(repository.path, 'README.md'))).to match(/\AContent of README\.md in #{ee_fixture.fixture_path} is \h+\z/)

        commits = `git -C #{repository.path} log -1 --date-order --pretty=format:'%B'`.lines

        expect(commits).to start_with("Merge remote-tracking branch 'upstream/master' into #{default_options[:merge_branch]}\n")
        expect(commits).not_to include('[ci skip]')
      end
    end

    context 'when a conflict is detected' do
      before do
        ce_fixture.unique_update_to_file!('README.md', author: current_git_author)
      end

      it 'returns the conflicts data' do
        expect(subject.execute).to eq(
          [{ user: current_git_author_name, path: 'README.md', conflict_type: 'UU' }])
      end

      it 'commits the conflicts and includes `[ci skip]` in the commit message' do
        subject.execute

        expect(ee_rugged_repo).to have_head(default_options[:merge_branch])
        expect(File.read(File.join(repository.path, 'README.md'))).to match <<~CONTENT
          <<<<<<< HEAD
          Content of README.md in #{ee_fixture.fixture_path} is \\h+
          =======
          Content of README.md in #{ce_fixture.fixture_path} is \\h+
          >>>>>>> upstream/master
          CONTENT

        last_commit = `git -C #{repository.path} log -1`

        expect(last_commit).to include("Merge remote-tracking branch 'upstream/master' into #{default_options[:merge_branch]}\n")
        expect(last_commit).to include("[ci skip]")
      end
    end

    it 'pushed the merge branch' do
      expect(repository).to receive(:push).with(ee_repo_url, default_options[:merge_branch])

      subject.execute
    end
  end
end
