require 'spec_helper'
require 'remote_repository'

describe RemoteRepository do
  let(:fixture) { ReleaseFixture.new }
  let(:repo_path) { File.join('/tmp', fixture.class.repository_name) }
  let(:repo_url) { "file://#{fixture.fixture_path}" }
  let(:repo_remotes) do
    { gitlab: repo_url, github: 'https://example.com/foo/bar/baz.git' }
  end

  before do
    fixture.rebuild_fixture!
  end

  describe '.get' do
    it 'generates a name from the remote path' do
      remotes = {
        dev:    'https://example.com/foo/bar/dev.git',
        origin: 'https://gitlab.com/foo/bar/gitlab.git'
      }

      expect(described_class).to receive(:new).with('/tmp/dev', anything)

      described_class.get(remotes)
    end

    it 'accepts a repository name' do
      expect(described_class).to receive(:new).with('/tmp/foo', anything)

      described_class.get({}, 'foo')
    end

    it 'passes remotes to the initializer' do
      expect(described_class).to receive(:new).with(anything, :remotes)

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
      it 'fetches and checkouts the branch with an history of 1' do
        subject.ensure_branch_exists('branch-1')

        aggregate_failures do
          expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-1'
          expect(File.read(File.join(repo_path, 'README.md'))).to eq 'Sample README.md'
          expect(`git -C #{repo_path} log --oneline | wc -l`.to_i).to eq(1)
        end
      end
    end

    context 'with a non-existing branch' do
      it 'creates and checkouts the branch with an history of 1' do
        subject.ensure_branch_exists('branch-2')

        aggregate_failures do
          expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-2'
          expect(File.read(File.join(repo_path, 'README.md'))).to eq 'Sample README.md'
          expect(`git -C #{repo_path} log --oneline | wc -l`.to_i).to eq(1)
        end
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
    end

    it 'commits the given file with the given message in the current branch' do
      expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-1'

      subject.commit('README.md', 'Update README')

      expect(`git -C #{repo_path} symbolic-ref HEAD`.strip).to eq 'refs/heads/branch-1'
      expect(File.read(File.join(repo_path, 'README.md'))).to eq 'Cool'

      commit_info = `git -C #{repo_path} show HEAD --name-only --oneline`.lines
      expect(commit_info[0]).to match(/\A\w{7} Update README\Z/)
      expect(commit_info[1]).to match(/\AREADME.md\Z/)
    end
  end

  describe '#pull_from_all_remotes' do
    let(:repository) { described_class.get(Hash[*repo_remotes.first]) }

    context 'when there are conflicts' do
      it 'stops the script' do
        allow(repository).to receive(:conflicts?).and_return(true)

        expect { repository.pull_from_all_remotes('1-9-stable') }
          .to raise_error(described_class::CannotPullError)
      end
    end

    context 'when pull was successful' do
      it 'continues to the next command' do
        expect { repository.pull_from_all_remotes('master') }
          .not_to raise_error
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
