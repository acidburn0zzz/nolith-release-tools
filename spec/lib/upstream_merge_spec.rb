require 'spec_helper'

require 'upstream_merge'

describe UpstreamMerge, :silence_stdout, :aggregate_failures do
  include RuggedMatchers

  let(:ee_repo_name) { 'gitlab-ee-upstream-merge' }
  let(:ce_repo_name) { 'gitlab-ce-upstream-merge' }
  let(:ee_fixture) { ConflictFixture.new(File.expand_path("../fixtures/repositories/#{ee_repo_name}", __dir__)) }
  let(:ce_fixture) { ConflictFixture.new(File.expand_path("../fixtures/repositories/#{ce_repo_name}", __dir__)) }
  let(:ee_repo_path) { File.join('/tmp', ee_repo_name) }
  let(:ce_repo_path) { File.join('/tmp', ce_repo_name) }
  let(:ee_repo_url) { "file://#{ee_fixture.fixture_path}" }
  let(:default_options) do
    {
      origin: ee_repo_url,
      upstream: "file://#{ce_fixture.fixture_path}",
      merge_branch: "ce-to-ee-#{SecureRandom.hex}"
    }
  end
  let(:git_author_name) { 'Your Name' }
  let(:git_author) { { name: git_author_name, email: 'author@example.org' } }

  subject { described_class.new(default_options) }

  before do
    ee_fixture.rebuild_fixture!(author: git_author)
    ce_fixture.rebuild_fixture!(author: git_author)

    # Disable cleanup so that we can see what's the state of the temp Git repos
    allow_any_instance_of(RemoteRepository).to receive(:cleanup).and_return(true)
  end

  after do
    # Manually perform the cleanup we disabled in the `before` block
    FileUtils.rm_r(ee_repo_path, secure: true) if File.exist?(ee_repo_path)
    FileUtils.rm_r(ce_repo_path, secure: true) if File.exist?(ce_repo_path)
  end

  describe '#execute' do
    let(:ee_rugged_repo) { Rugged::Repository.new(ee_repo_path) }

    before do
      ce_fixture.unique_update_to_file('CONTRIBUTING.md', author: git_author)
      ee_fixture.unique_update_to_file('README.md', author: git_author)
    end

    context 'when no conflict is detected' do
      it 'creates a branch and merges upstream/master into it' do
        subject.execute

        expect(ee_rugged_repo).to have_head(default_options[:merge_branch])
        expect(File.read(File.join(ee_repo_path, 'CONTRIBUTING.md'))).to match(/\AContent of CONTRIBUTING\.md in #{ce_fixture.fixture_path} is \h+\z/)
        expect(File.read(File.join(ee_repo_path, 'README.md'))).to match(/\AContent of README\.md in #{ee_fixture.fixture_path} is \h+\z/)

        expect(ee_rugged_repo).to have_commit_message <<~COMMIT_MESSAGE
          Merge remote-tracking branch 'upstream/master' into #{default_options[:merge_branch]}
        COMMIT_MESSAGE
      end
    end

    context 'when a conflict is detected' do
      before do
        ce_fixture.unique_update_to_file('README.md', author: git_author)
      end

      it 'returns the conflicts data' do
        expect(subject.execute).to eq(
          [{ user: git_author_name, path: 'README.md', conflict_type: 'UU' }])
      end

      it 'commits the conflicts and includes `[ci skip]` in the commit message' do
        subject.execute

        expect(ee_rugged_repo).to have_head(default_options[:merge_branch])
        expect(File.read(File.join(ee_repo_path, 'README.md'))).to match <<~CONTENT
          <<<<<<< HEAD
          Content of README.md in #{ee_fixture.fixture_path} is \\h+
          =======
          Content of README.md in #{ce_fixture.fixture_path} is \\h+
          >>>>>>> upstream/master
        CONTENT

        expect(ee_rugged_repo).to have_commit_message <<~COMMIT_MESSAGE
          Merge remote-tracking branch 'upstream/master' into #{default_options[:merge_branch]}

          # Conflicts:
          #\tREADME.md

          [ci skip]
        COMMIT_MESSAGE
      end
    end

    it 'does push the merge branch if there is a change' do
      ce_fixture.unique_update_to_file('README.md', author: git_author)

      expect(subject.__send__(:repository)).to receive(:push).with(ee_repo_url, default_options[:merge_branch])

      subject.execute
    end

    it 'does not push the merge branch if there is no change' do
      expect(subject.__send__(:repository)).to receive(:push).with(ee_repo_url, default_options[:merge_branch])

      subject.execute
    end
  end
end
