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
    FileUtils.rm_rf(ee_repo_path, secure: true) if File.exist?(ee_repo_path)
    FileUtils.rm_rf(ce_repo_path, secure: true) if File.exist?(ce_repo_path)
  end

  describe '#execute!' do
    let(:ee_rugged_repo) { Rugged::Repository.new(ee_repo_path) }

    context 'when downstream does not have the latest upstream changes' do
      before do
        ce_fixture.update_file('CONTRIBUTING.md', 'New CONTRIBUTING.md from CE', author: git_author)
        ee_fixture.update_file('README.md', 'New README.md from EE', author: git_author)
      end

      context 'when no conflict is detected' do
        it 'creates a branch and merges upstream/master into it' do
          subject.execute!

          expect(ee_rugged_repo).to have_head(default_options[:merge_branch])
          expect(File.read(File.join(ee_repo_path, 'CONTRIBUTING.md'))).to eq('New CONTRIBUTING.md from CE')
          expect(File.read(File.join(ee_repo_path, 'README.md'))).to eq('New README.md from EE')

          expect(ee_rugged_repo).to have_commit_message <<~COMMIT_MESSAGE
            Merge remote-tracking branch 'upstream/master' into #{default_options[:merge_branch]}
          COMMIT_MESSAGE
        end
      end

      context 'when a conflict is detected' do
        before do
          ce_fixture.update_file('README.md', 'New README.md from CE', author: git_author)
        end

        it 'returns the conflicts data' do
          expect(subject.execute!).to eq(
            [{ user: git_author_name, path: 'README.md', conflict_type: 'UU' }])
        end

        it 'commits the conflicts and includes `[ci skip]` in the commit message' do
          subject.execute!

          expect(ee_rugged_repo).to have_head(default_options[:merge_branch])
          expect(File.read(File.join(ee_repo_path, 'README.md'))).to eq <<~CONTENT
            <<<<<<< HEAD
            New README.md from EE
            =======
            New README.md from CE
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

      it 'pushed the merge branch' do
        expect(subject.__send__(:repository)).to receive(:push).with(ee_repo_url, default_options[:merge_branch]).and_return(true)

        subject.execute!
      end

      it 'raises a PushError upon failure' do
        expect(subject.__send__(:repository)).to receive(:push).with(ee_repo_url, default_options[:merge_branch]).and_return(false)

        expect { subject.execute! }.to raise_error(described_class::PushFailed)
      end
    end

    context 'when all upstream commits are already in downstream' do
      it 'raises a DownstreamAlreadyUpToDate error' do
        expect { subject.execute! }.to raise_error(described_class::DownstreamAlreadyUpToDate)

        expect(ee_rugged_repo).to have_head(default_options[:merge_branch])
        expect(File.read(File.join(ee_repo_path, 'CONTRIBUTING.md'))).to eq('Sample CONTRIBUTING.md')
        expect(File.read(File.join(ee_repo_path, 'README.md'))).to eq('Sample README.md')

        expect(ee_rugged_repo).to have_commit_message('Add a sample README.md')
      end
    end
  end
end
