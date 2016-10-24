require 'spec_helper'
require 'repository'

describe Repository do
  let(:repo_name) { 'release-tools-test-gitlab' }
  let(:repo_url) { 'https://gitlab.com/gitlab-org/release-tools-test-gitlab.git' }
  let(:github_repo_url) { repo_url.sub('gitlab', 'github') }
  let(:repo_remotes) do
    { gitlab: repo_url, github: github_repo_url }
  end
  let(:repo_path) { File.join('/tmp', repo_name) }

  after { FileUtils.rm_rf(repo_path, secure: true) }

  describe '.get' do
    context 'without a repo name' do
      it_behaves_like 'a sane Git repository' do
        let(:repo) { described_class.get(repo_remotes) }
      end
    end

    context 'with a repo name' do
      before { FileUtils.rm_rf(File.join('/tmp', 'hello-world'), secure: true) }
      after { FileUtils.rm_rf(File.join('/tmp', 'hello-world'), secure: true) }

      it_behaves_like 'a sane Git repository' do
        let(:repo_name) { 'hello-world' }
        let(:repo) { described_class.get(repo_remotes, repo_name) }
      end
    end

    it 'adds the given remotes to the Git repo' do
      repo = described_class.get(repo_remotes)
      expect(repo.remotes).to eq repo_remotes

      remotes_info = Dir.chdir(repo_path) { `git remote -v`.lines }
      expect(remotes_info.size).to eq 4
      expect(remotes_info[0].strip).to eq "github\t#{github_repo_url} (fetch)"
      expect(remotes_info[1].strip).to eq "github\t#{github_repo_url} (push)"
      expect(remotes_info[2].strip).to eq "gitlab\t#{repo_url} (fetch)"
      expect(remotes_info[3].strip).to eq "gitlab\t#{repo_url} (push)"
    end
  end

  describe '#path' do
    context 'when no name is given' do
      subject { described_class.get(repo_remotes) }

      it { expect(subject.path).to eq File.join('/tmp', repo_name) }
    end

    context 'when a name is given' do
      subject { described_class.get(repo_remotes, 'hello-world') }
      before { FileUtils.rm_rf(File.join('/tmp', 'hello-world'), secure: true) }
      after { FileUtils.rm_rf(File.join('/tmp', 'hello-world'), secure: true) }

      it { expect(subject.path).to eq File.join('/tmp', 'hello-world') }
    end
  end

  describe '#canonical_remote' do
    subject { described_class.get(repo_remotes) }

    it { expect(subject.canonical_remote.name).to eq :gitlab }
    it { expect(subject.canonical_remote.url).to eq repo_url }
  end

  describe '#remotes' do
    subject { described_class.get(repo_remotes) }

    it { expect(subject.remotes).to eq repo_remotes }
  end

  describe '#ensure_branch_exists' do
    subject { described_class.get(repo_remotes) }

    context 'with an existing branch' do
      it 'fetches and checkouts the branch with an history of 1' do
        subject.ensure_branch_exists('branch-1')

        expect(Dir.chdir(repo_path) { `git symbolic-ref HEAD`.strip }).to eq 'refs/heads/branch-1'
        expect(File.open(File.join(repo_path, 'README.md')).read).to eq 'README.md in branch-1'
        expect(Dir.chdir(repo_path) { `git log --oneline | wc -l`.to_i }).to eq(1)
      end
    end

    context 'with a non-existing branch' do
      it 'creates and checkouts the branch with an history of 1' do
        subject.ensure_branch_exists('branch-2')

        expect(Dir.chdir(repo_path) { `git symbolic-ref HEAD`.strip }).to eq 'refs/heads/branch-2'
        expect(File.open(File.join(repo_path, 'README.md')).read).to eq 'This is a sample README.'
        expect(Dir.chdir(repo_path) { `git log --oneline | wc -l`.to_i }).to eq(1)
      end
    end
  end

  describe '#create_tag' do
    subject { described_class.get(repo_remotes) }

    it 'creates the tag in the current branch' do
      subject.ensure_branch_exists('branch-1')
      expect(Dir.chdir(repo_path) { `git symbolic-ref HEAD`.strip }).to eq 'refs/heads/branch-1'

      subject.create_tag('v42')

      expect(Dir.chdir(repo_path) { `git symbolic-ref HEAD`.strip }).to eq 'refs/heads/branch-1'
      expect(Dir.chdir(repo_path) { `git tag -l`.strip }).to eq 'v42'
    end
  end

  describe '#write_file' do
    subject { described_class.get(repo_remotes) }

    context 'with an existing file' do
      it 'overwrites the file' do
        subject.write_file('README.md', 'Cool')

        expect(File.open(File.join(repo_path, 'README.md')).read).to eq 'Cool'
      end
    end

    context 'with a non-existing file' do
      it 'creates the file' do
        subject.write_file('PROCESS.md', 'Just do it!')

        expect(File.open(File.join(repo_path, 'PROCESS.md')).read).to eq 'Just do it!'
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
      expect(Dir.chdir(repo_path) { `git symbolic-ref HEAD`.strip }).to eq 'refs/heads/branch-1'

      subject.commit('README.md', 'Update README')

      expect(Dir.chdir(repo_path) { `git symbolic-ref HEAD`.strip }).to eq 'refs/heads/branch-1'
      expect(File.open(File.join(repo_path, 'README.md')).read).to eq 'Cool'

      commit_info = Dir.chdir(repo_path) { `git show HEAD --name-only --oneline`.lines }
      expect(commit_info[0]).to match /\A\w{7} Update README\Z/
      expect(commit_info[1]).to match /\AREADME.md\Z/
    end
  end

  describe '#pull_from_all_remotes' do
    subject { described_class.get(Hash[*repo_remotes.first]) }
    before { subject.ensure_branch_exists('master') }

    context 'when there are conflicts' do
      it 'stops the script' do
        expect {
          subject.pull_from_all_remotes('1-9-stable')
        }.to raise_error(Repository::CannotPullError)
      end
    end

    context 'when pull was successful' do
      it 'continues to the next command' do
        expect {
          subject.pull_from_all_remotes('master')
        }.not_to raise_error
      end
    end
  end

  describe '#cleanup' do
    subject { described_class.get(repo_remotes) }

    it 'removes any existing dir with the given name in /tmp' do
      subject.ensure_branch_exists('master') # To actually clone the repo
      expect(File.exists?(repo_path)).to be_truthy

      subject.cleanup

      expect(File.exists?(repo_path)).to be_falsy
    end
  end
end
