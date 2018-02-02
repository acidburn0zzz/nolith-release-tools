require 'spec_helper'
require 'remote_repository'

describe RemoteRepository do
  include RuggedMatchers

  let(:fixture) { ReleaseFixture.new }
  let(:repo_path) { File.join('/tmp', fixture.class.repository_name) }
  let(:rugged_repo) { Rugged::Repository.new(repo_path) }
  let(:repo_url) { "file://#{fixture.fixture_path}" }
  let(:repo_remotes) do
    { gitlab: repo_url, github: 'https://example.com/foo/bar/baz.git' }
  end

  before do
    fixture.rebuild_fixture!
  end

  describe '.get' do
    let(:remotes) do
      {
        dev:    'https://example.com/foo/bar/dev.git',
        origin: 'https://gitlab.com/foo/bar/gitlab.git'
      }
    end

    it 'generates a name from the first remote' do
      expect(described_class).to receive(:new).with('/tmp/dev', anything, anything)

      described_class.get(remotes)
    end

    it 'accepts a repository name' do
      expect(described_class).to receive(:new).with('/tmp/foo', anything, anything)

      described_class.get(remotes, 'foo')
    end

    it 'passes remotes to the initializer' do
      expect(described_class).to receive(:new).with(anything, remotes, anything)

      described_class.get(remotes)
    end

    it 'accepts a :global_depth option' do
      expect(described_class).to receive(:new).with(anything, anything, global_depth: 100)

      described_class.get(remotes, global_depth: 100)
    end
  end

  describe 'initialize', :silence_stdout do
    it 'performs cleanup' do
      expect_any_instance_of(described_class).to receive(:cleanup)

      described_class.new(repo_path, {})
    end

    it 'performs a shallow clone of the repository' do
      described_class.new(repo_path, repo_remotes)

      # Note: Rugged has no clean way to do this, so we'll shell out
      expect(`git -C #{repo_path} log --oneline | wc -l`.to_i)
        .to eq(1)
    end

    it 'adds remotes to the repository' do
      expect_any_instance_of(described_class).to receive(:remotes=)
        .with(:remotes)

      described_class.new('foo', :remotes)
    end

    it 'assigns path' do
      repository = described_class.new('foo', {})

      expect(repository.path).to eq 'foo'
    end
  end

  describe '#remotes=', :silence_stdout, :aggregate_failures do
    it 'assigns the canonical remote' do
      remotes = { origin: repo_url }

      repository = described_class.new(repo_path, remotes)

      expect(repository.canonical_remote.name).to eq(:origin)
      expect(repository.canonical_remote.url).to eq(repo_url)
    end

    it 'assigns remotes' do
      remotes = { origin: repo_url }

      repository = described_class.new(repo_path, remotes)

      expect(repository.remotes).to eq(remotes)
    end

    it 'adds remotes to the repository', :aggregate_failures do
      remotes = {
        origin: repo_url,
        github: '/foo/bar/baz.git'
      }

      repository = described_class.new(repo_path, remotes)
      rugged = Rugged::Repository.new(repository.path)

      expect(rugged.remotes.count).to eq(2)
      expect(rugged.remotes['origin'].url).to eq(repo_url)
      expect(rugged.remotes['github'].url).to eq('/foo/bar/baz.git')
    end
  end

  describe '#ensure_branch_exists', :silence_stdout do
    subject { described_class.get(repo_remotes) }

    context 'with an existing branch' do
      it 'fetches and checks out the branch with the configured global depth', :aggregate_failures do
        subject.ensure_branch_exists('branch-1')

        expect(rugged_repo).to have_head('branch-1')
        expect(rugged_repo).to have_blob('README.md').with('Sample README.md')
        expect(`git -C #{repo_path} log --oneline | wc -l`.to_i).to eq(1)
      end
    end

    context 'with a non-existing branch' do
      it 'creates and checks out the branch with the configured global depth', :aggregate_failures do
        subject.ensure_branch_exists('branch-2')

        expect(rugged_repo).to have_head('branch-2')
        expect(rugged_repo).to have_blob('README.md').with('Sample README.md')
        expect(`git -C #{repo_path} log --oneline | wc -l`.to_i).to eq(1)
      end
    end
  end

  describe '#fetch', :silence_stdout do
    subject { described_class.get(repo_remotes) }

    it 'fetches the branch with the default configured global depth' do
      subject.fetch('branch-1')

      expect(`git -C #{repo_path} log --oneline refs/heads/branch-1 | wc -l`.to_i).to eq(1)
    end

    context 'with a depth option given' do
      it 'fetches the branch up to the given depth' do
        subject.fetch('branch-1', depth: 2)

        expect(`git -C #{repo_path} log --oneline refs/heads/branch-1 | wc -l`.to_i).to eq(2)
      end
    end
  end

  describe '#checkout_new_branch', :silence_stdout do
    subject { described_class.get(repo_remotes) }

    it 'creates and checks out a new branch' do
      subject.checkout_new_branch('new-branch')

      expect(rugged_repo).to have_version('pages').at('4.5.0')
    end

    context 'with a given base branch' do
      it 'creates and checks out a new branch based on the given base branch' do
        subject.checkout_new_branch('new-branch', base: '9-1-stable')

        expect(rugged_repo).to have_version('pages').at('4.4.4')
      end
    end
  end

  describe '#create_tag', :silence_stdout do
    subject { described_class.get(repo_remotes) }

    it 'creates the tag in the current branch' do
      subject.ensure_branch_exists('branch-1')
      subject.create_tag('v42')

      expect(rugged_repo.tags['v42'].target).to eq(rugged_repo.branches['branch-1'].target)
    end
  end

  describe '#write_file', :silence_stdout do
    subject { described_class.get(repo_remotes) }

    context 'with an existing file' do
      it 'overwrites the file' do
        subject.write_file('README.md', 'Cool')

        expect(File.read(File.join(repo_path, 'README.md'))).to eq 'Cool'
      end
    end

    context 'with a non-existing file' do
      it 'creates the file' do
        subject.write_file('PROCESS.md', 'Just do it!')

        expect(File.read(File.join(repo_path, 'PROCESS.md'))).to eq 'Just do it!'
      end
    end
  end

  describe '#commit', :silence_stdout, :aggregate_failures do
    subject { described_class.get(repo_remotes) }

    before do
      subject.ensure_branch_exists('branch-1')
      subject.write_file('README.md', 'Cool')
      subject.write_file('CONTRIBUTING.md', 'Be nice!')
    end

    it 'commits the given files with the given message in the current branch' do
      expect(
        subject.commit(%w[README.md CONTRIBUTING.md],
          message: 'Update README and CONTRIBUTING')
      ).to be(true)

      expect(rugged_repo).to have_commit_title('Update README and CONTRIBUTING')
      expect(rugged_repo).to have_blob('README.md').with('Cool')
      expect(rugged_repo).to have_blob('CONTRIBUTING.md').with('Be nice!')
    end

    context 'when no_edit: true and amend: true are set' do
      it 'commits the given files and amend the last commit in the current branch' do
        expect(
          subject.commit(%w[README.md CONTRIBUTING.md],
            no_edit: true,
            amend: true)
        ).to be(true)

        expect(rugged_repo).to have_commit_title('Add GITLAB_SHELL_VERSION, GITLAB_WORKHORSE_VERSION, GITALY_SERVER_VERSION, VERSION')
        expect(rugged_repo).to have_blob('README.md').with('Cool')
        expect(rugged_repo).to have_blob('CONTRIBUTING.md').with('Be nice!')
      end
    end

    context 'when :author is set' do
      it 'commits the given files and amends the last commit in the current branch' do
        expect(
          subject.commit(%w[README.md CONTRIBUTING.md],
            message: 'Update README and CONTRIBUTING',
            author: 'Your Name <author@example.com>')
        ).to be(true)

        expect(rugged_repo).to have_blob('README.md').with('Cool')
        expect(rugged_repo).to have_blob('CONTRIBUTING.md').with('Be nice!')

        log_lines = subject.log(format: :author)

        expect(log_lines).to start_with("Your Name\n")
      end
    end

    context 'when the Git command fails' do
      let(:error) { 'error message' }

      before do
        allow(subject).to receive(:run_git).with(%w[add README.md])
        expect(subject).to receive(:run_git).with(%w[commit])
          .and_return([error, double(success?: false)])
      end

      it 'raises a CannotCommitError exception' do
        expect { subject.commit(%w[README.md]) }
          .to raise_error(RemoteRepository::CannotCommitError, error)
      end
    end
  end

  describe '#merge', :silence_stdout, :aggregate_failures do
    subject { described_class.get(repo_remotes, global_depth: 10) }

    before do
      subject.fetch('master')
      subject.ensure_branch_exists('branch-1')
      subject.ensure_branch_exists('branch-2')
      subject.write_file('README.md', 'Nice')
      subject.commit('README.md', message: 'Update README.md')
      subject.ensure_branch_exists('branch-1')
    end

    it 'commits the given files with the given message in the current branch' do
      expect(subject.merge('branch-2', 'branch-1', no_ff: true).status).to be_success
      log = subject.log(format: :message)

      expect(log).to start_with("Merge branch 'branch-2' into branch-1\n")
      expect(File.read(File.join(repo_path, 'README.md'))).to eq 'Nice'
    end
  end

  describe '#status', :silence_stdout do
    subject { described_class.get(repo_remotes) }

    before do
      subject.ensure_branch_exists('branch-1')
      subject.write_file('README.md', 'Cool')
      subject.write_file('CONTRIBUTING.md', 'Be nice!')
    end

    it 'calls "git log"' do
      expect(subject).to receive(:run_git).with(%w[status])

      subject.status
    end

    context 'when short is true' do
      it 'shows the modified files in the short form' do
        expect(subject).to receive(:run_git).with(%w[status --short])

        subject.status(short: true)
      end
    end
  end

  describe '#log', :silence_stdout do
    subject { described_class.get(repo_remotes, global_depth: 10) }

    before do
      subject.fetch('master', depth: 10)
      subject.checkout_new_branch('branch-1')
      subject.checkout_new_branch('branch-2')
      subject.write_file('README.md', 'Nice')
      subject.commit('README.md', message: 'Update README.md')
      subject.ensure_branch_exists('branch-1')
      subject.merge('branch-2', 'branch-1', no_ff: true)
    end

    it 'shows commits' do
      expect(subject).to receive(:run_git).with(%w[log --author-date-order])

      subject.log
    end

    context 'when latest is true' do
      it 'shows only the latest commit' do
        expect(subject).to receive(:run_git).with(%w[log --author-date-order -1])

        subject.log(latest: true)
      end
    end

    context 'when no_merges is true' do
      it 'shows non-merge commits' do
        expect(subject).to receive(:run_git).with(%w[log --author-date-order --no-merges])

        subject.log(no_merges: true)
      end
    end

    context 'when author_name is true' do
      it 'shows authors only' do
        expect(subject).to receive(:run_git).with(%w[log --author-date-order --format='%an'])

        subject.log(format: :author)
      end
    end

    context 'when message is true' do
      it 'shows messages only' do
        expect(subject).to receive(:run_git).with(%w[log --author-date-order --format='%B'])

        subject.log(format: :message)
      end
    end

    context 'when :paths is set' do
      it 'shows commits for the given file when :paths is a string' do
        expect(subject).to receive(:run_git).with(%w[log --author-date-order -- README.md])

        subject.log(paths: 'README.md')
      end

      it 'shows commits for the given files when :paths is an array' do
        expect(subject).to receive(:run_git).with(%w[log --author-date-order -- README.md VERSION])

        subject.log(paths: %w[README.md VERSION])
      end
    end
  end

  describe '#head', :silence_stdout do
    subject { described_class.get(repo_remotes) }

    before do
      subject.ensure_branch_exists('branch-1')
    end

    it 'shows current HEAD sha' do
      expect(subject.head).to eq(`git -C #{repo_path} rev-parse --verify HEAD`.strip)
    end
  end

  describe '#pull', :silence_stdout do
    subject { described_class.get(repo_remotes) }

    before do
      subject.ensure_branch_exists('master')
    end

    it 'pulls the branch with the configured depth' do
      expect { subject.pull('master') }
        .not_to(change { subject.log(format: :message).lines.size })
    end

    context 'with a depth option given' do
      it 'pulls the branch with to the given depth' do
        expect { subject.pull('master', depth: 2) }
          .to change { subject.log(format: :message).lines.size }.from(1).to(2)
      end
    end
  end

  describe '#pull_from_all_remotes', :silence_stdout do
    subject { described_class.get(Hash[*repo_remotes.first]) }

    context 'when there are conflicts' do
      it 'raises a CannotPullError error' do
        allow(subject).to receive(:conflicts?).and_return(true)

        expect { subject.pull_from_all_remotes('1-9-stable') }
          .to raise_error(described_class::CannotPullError)
      end
    end

    it 'does not raise error' do
      expect { subject.pull_from_all_remotes('master') }
        .not_to raise_error
    end

    context 'with a depth option given' do
      it 'pulls the branch down to the given depth' do
        expect { subject.pull_from_all_remotes('master', depth: 2) }
          .to change { subject.log(format: :message).lines.size }.from(1).to(2)
      end
    end
  end

  describe '#cleanup', :silence_stdout do
    it 'removes the repository path' do
      repository = described_class.new(repo_path, {})

      expect(FileUtils).to receive(:rm_rf).with(repo_path, secure: true)

      repository.cleanup
    end
  end
end
