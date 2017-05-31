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
  let(:current_git_author) { `git config --get user.name`.strip }

  before do
    fixture.rebuild_fixture!
  end

  describe '.get' do
    it 'generates a name from the remote path' do
      remotes = {
        dev:    'https://example.com/foo/bar/dev.git',
        origin: 'https://gitlab.com/foo/bar/gitlab.git'
      }

      expect(described_class).to receive(:new).with('/tmp/dev', anything, anything)

      described_class.get(remotes)
    end

    it 'accepts a repository name' do
      expect(described_class).to receive(:new).with('/tmp/foo', anything, anything)

      described_class.get({}, 'foo')
    end

    it 'accepts a :global_depth option' do
      expect(described_class).to receive(:new).with('/tmp/foo', anything, global_depth: 100)

      described_class.get({}, 'foo', global_depth: 100)
    end

    it 'passes remotes to the initializer' do
      expect(described_class).to receive(:new).with(anything, :remotes, anything)

      described_class.get(:remotes, 'foo')
    end
  end

  describe 'initialize' do
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

  describe '#remotes=' do
    it 'assigns the canonical remote' do
      remotes = { origin: repo_url }

      repository = described_class.new(repo_path, remotes)

      aggregate_failures do
        expect(repository.canonical_remote.name).to eq(:origin)
        expect(repository.canonical_remote.url).to eq(repo_url)
      end
    end

    it 'assigns remotes' do
      remotes = { origin: repo_url }

      repository = described_class.new(repo_path, remotes)

      expect(repository.remotes).to eq(remotes)
    end

    it 'adds remotes to the repository' do
      remotes = {
        origin: repo_url,
        github: '/foo/bar/baz.git'
      }

      repository = described_class.new(repo_path, remotes)

      aggregate_failures do
        rugged = Rugged::Repository.new(repository.path)

        expect(rugged.remotes.count).to eq(2)

        expect(rugged.remotes['origin'].url).to eq(repo_url)
        expect(rugged.remotes['github'].url).to eq('/foo/bar/baz.git')
      end
    end
  end

  describe '#ensure_branch_exists' do
    subject { described_class.get(repo_remotes) }

    context 'with an existing branch' do
      it 'fetches and checkouts the branch with the configured global depth', :aggregate_failures do
        subject.ensure_branch_exists('branch-1')

        expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-1'
        expect(File.read(File.join(repo_path, 'README.md'))).to eq 'Sample README.md'
        expect(`git -C #{repo_path} log --oneline | wc -l`.to_i).to eq(1)
      end
    end

    context 'with a non-existing branch' do
      it 'creates and checkouts the branch with the configured global depth', :aggregate_failures do
        subject.ensure_branch_exists('branch-2')

        expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-2'
        expect(File.read(File.join(repo_path, 'README.md'))).to eq 'Sample README.md'
        expect(`git -C #{repo_path} log --oneline | wc -l`.to_i).to eq(1)
      end
    end
  end

  describe '#fetch' do
    subject { described_class.get(repo_remotes) }

    it 'fetches the branch with the default configure global depth' do
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

  describe '#checkout_new_branch' do
    subject { described_class.get(repo_remotes) }

    it 'creates and checkouts a new branch', :aggregate_failures do
      subject.checkout_new_branch('new-branch')

      expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/new-branch'
      expect(rugged_repo).to have_version('pages').at('4.5.0')
    end

    context 'with a given base_branch' do
      it 'create and checkouts a new branch based on the given base_branch', :aggregate_failures do
        subject.checkout_new_branch('new-branch', base_branch: '9-1-stable')

        expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/new-branch'
        expect(rugged_repo).to have_version('pages').at('4.4.4')
      end
    end
  end

  describe '#create_tag' do
    it 'creates the tag in the current branch' do
      repository = described_class.get(repo_remotes)
      rugged = Rugged::Repository.new(repository.path)

      repository.ensure_branch_exists('branch-1')
      repository.create_tag('v42')

      aggregate_failures do
        expect(rugged.head.name).to eq 'refs/heads/branch-1'
        expect(rugged.tags['v42']).not_to be_nil
      end
    end
  end

  describe '#write_file' do
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

  describe '#commit' do
    subject { described_class.get(repo_remotes) }

    before do
      subject.ensure_branch_exists('branch-1')
      subject.write_file('README.md', 'Cool')
      subject.write_file('CONTRIBUTING.md', 'Be nice!')
    end

    it 'commits the given files with the given message in the current branch' do
      expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-1'

      subject.commit(%w[README.md CONTRIBUTING.md], message: 'Update README and CONTRIBUTING')

      expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-1'
      expect(File.read(File.join(repo_path, 'README.md'))).to eq 'Cool'
      expect(File.read(File.join(repo_path, 'CONTRIBUTING.md'))).to eq 'Be nice!'

      commit_info = `git -C #{repo_path} show HEAD --name-only --oneline`

      expect(commit_info).to match Regexp.new <<~HEREDOC
        \\w{7} Update README and CONTRIBUTING
        CONTRIBUTING.md
        README.md
      HEREDOC
    end

    context 'when no_edit: true and amend: true are set' do
      it 'commits the given files and amend the last commit in the current branch' do
        expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-1'

        subject.commit(%w[README.md CONTRIBUTING.md], no_edit: true, amend: true)

        expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-1'
        expect(File.read(File.join(repo_path, 'README.md'))).to eq 'Cool'
        expect(File.read(File.join(repo_path, 'CONTRIBUTING.md'))).to eq 'Be nice!'

        commit_info = `git -C #{repo_path} show HEAD --name-only --oneline`

        expect(commit_info).to match Regexp.new <<~HEREDOC
          \\w{7} Add GITLAB_SHELL_VERSION, GITLAB_WORKHORSE_VERSION, GITALY_SERVER_VERSION, VERSION
          CONTRIBUTING.md
          GITALY_SERVER_VERSION
          GITLAB_SHELL_VERSION
          GITLAB_WORKHORSE_VERSION
          README.md
          VERSION
        HEREDOC
      end
    end

    context 'when :author is set' do
      it 'commits the given files and amends the last commit in the current branch' do
        expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-1'

        subject.commit(%w[README.md CONTRIBUTING.md], message: 'Update README and CONTRIBUTING', author: 'Your Name <author@example.com>')

        expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-1'
        expect(File.read(File.join(repo_path, 'README.md'))).to eq 'Cool'
        expect(File.read(File.join(repo_path, 'CONTRIBUTING.md'))).to eq 'Be nice!'

        log_lines = subject.log(author_name: true)

        expect(log_lines).to start_with("Your Name\n")
      end
    end
  end

  describe '#merge' do
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
      expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-1'

      subject.merge('branch-2', 'branch-1', no_ff: true)
      log = subject.log(message: true)

      expect(log).to start_with("Merge branch 'branch-2' into branch-1\n")
      expect(File.read(File.join(repo_path, 'README.md'))).to eq 'Nice'
    end
  end

  describe '#status' do
    subject { described_class.get(repo_remotes) }

    before do
      subject.ensure_branch_exists('branch-1')
      subject.write_file('README.md', 'Cool')
      subject.write_file('CONTRIBUTING.md', 'Be nice!')
    end

    it 'shows the modified files' do
      expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-1'

      status = subject.status

      expect(status).to eq <<-CONTENT.strip_heredoc
        On branch branch-1
        Changes not staged for commit:
          (use "git add <file>..." to update what will be committed)
          (use "git checkout -- <file>..." to discard changes in working directory)

        	modified:   README.md

        Untracked files:
          (use "git add <file>..." to include in what will be committed)

        	CONTRIBUTING.md

        no changes added to commit (use "git add" and/or "git commit -a")
        CONTENT
    end

    context 'when short is true' do
      it 'shows the modified files in the short form' do
        expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-1'

        status = subject.status(short: true)

        expect(status).to eq(" M README.md\n?? CONTRIBUTING.md\n")
      end
    end
  end

  describe '#log' do
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
      expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-1'
      expect(subject.log).to match Regexp.new <<~HEREDOC
        commit \\w+
        Merge: \\w+ \\w+
        Author: .+
        Date: .+

            Merge branch 'branch-2' into branch-1

        commit \\w+
        Author: .+
        Date: .+
      HEREDOC
    end

    context 'when latest is true' do
      it 'shows only the latest commit' do
        expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-1'

        log = subject.log(latest: true)

        expect(log.lines.size).to eq(6)
        expect(log).to match Regexp.new <<~HEREDOC
          commit \\w+
          Merge: \\w+ \\w+
          Author: .+
          Date: .+

              Merge branch 'branch-2' into branch-1
        HEREDOC
      end
    end

    context 'when no_merges is true' do
      it 'shows non-merge commits' do
        expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-1'
        expect(File.read(File.join(repo_path, 'README.md'))).to eq 'Nice'

        log = subject.log(no_merges: true, message: true)

        expect(log).to match Regexp.new <<~HEREDOC
          Update README.md
          Add GITALY_SERVER_VERSION, GITLAB_PAGES_VERSION, GITLAB_SHELL_VERSION, GITLAB_WORKHORSE_VERSION, VERSION
          Add GITLAB_PAGES_VERSION
          Add GITLAB_SHELL_VERSION, GITLAB_WORKHORSE_VERSION, GITALY_SERVER_VERSION, VERSION
        HEREDOC
      end
    end

    context 'when author_name is true' do
      it 'shows authors only' do
        expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-1'
        expect(File.read(File.join(repo_path, 'README.md'))).to eq 'Nice'

        log = subject.log(author_name: true)

        expect(log).to match Regexp.new <<~HEREDOC
          #{current_git_author}
          #{current_git_author}
        HEREDOC
      end
    end

    context 'when message is true' do
      it 'shows messages only' do
        expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-1'
        expect(File.read(File.join(repo_path, 'README.md'))).to eq 'Nice'

        log = subject.log(message: true)

        expect(log).to match Regexp.new <<~HEREDOC
          Merge branch 'branch-2' into branch-1
          Update README.md
          Add GITALY_SERVER_VERSION, GITLAB_PAGES_VERSION, GITLAB_SHELL_VERSION, GITLAB_WORKHORSE_VERSION, VERSION
          Add GITLAB_PAGES_VERSION
        HEREDOC
      end
    end

    context 'when :files is set' do
      it 'shows commits for the given file only' do
        expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-1'
        expect(File.read(File.join(repo_path, 'README.md'))).to eq 'Nice'

        log = subject.log(files: %w[README.md VERSION], message: true)

        expect(log).to match Regexp.new <<~HEREDOC.chomp
          Update README.md
          Add GITALY_SERVER_VERSION, GITLAB_PAGES_VERSION, GITLAB_SHELL_VERSION, GITLAB_WORKHORSE_VERSION, VERSION
          Add GITLAB_SHELL_VERSION, GITLAB_WORKHORSE_VERSION, GITALY_SERVER_VERSION, VERSION
          Add empty README.md
        HEREDOC
      end
    end
  end

  describe '#head' do
    subject { described_class.get(repo_remotes) }

    before do
      subject.ensure_branch_exists('branch-1')
    end

    it 'shows current HEAD sha' do
      expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-1'

      expect(subject.head).to eq(`git -C #{repo_path} rev-parse --verify HEAD`.strip)
    end
  end

  describe '#pull' do
    subject { described_class.get(repo_remotes) }

    before do
      subject.ensure_branch_exists('master')
    end

    it 'pulls the branch with the configured depth' do
      expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/master'
      expect { subject.pull('master') }
        .not_to(change { subject.log(message: true).lines.size })
    end

    context 'with a depth option given' do
      it 'pulls the branch with to the given depth' do
        expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/master'
        expect { subject.pull('master', depth: 2) }
          .to change { subject.log(message: true).lines.size }.from(1).to(2)
      end
    end
  end

  describe '#pull_from_all_remotes' do
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
        expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/master'
        expect { subject.pull_from_all_remotes('master', depth: 2) }
          .to change { subject.log(message: true).lines.size }.from(1).to(2)
      end
    end
  end

  describe '#cleanup' do
    it 'removes the repository path' do
      repository = described_class.new(repo_path, {})

      expect(FileUtils).to receive(:rm_rf).with(repo_path, secure: true)

      repository.cleanup
    end
  end
end
