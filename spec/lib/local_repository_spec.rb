require 'spec_helper'
require 'local_repository'

describe LocalRepository, :silence_stdout do
  let(:fixture) { LocalRepositoryFixture.new }
  let(:repo_path) { File.join('/tmp', fixture.class.repository_name) }
  let(:repo_url) { "file://#{fixture.fixture_path}" }
  let(:repo_remotes) do
    { origin: repo_url, github: 'https://example.com/foo/bar/baz.git' }
  end
  let(:repo) { RemoteRepository.get(repo_remotes) }

  before do
    fixture.rebuild_fixture!
  end

  context 'up to date repository' do
    context 'master branch' do
      it 'returns true' do
        ensure_branch_exists('master')

        in_repo_path do
          expect(described_class.ready?).to be true
        end
      end
    end

    context 'different branch' do
      it 'returns false' do
        ensure_branch_exists('new-branch')

        in_repo_path do
          expect(described_class.ready?).to be false
        end
      end
    end
  end

  context 'outdated repository' do
    before do
      ensure_branch_exists('master')

      in_repo_path do
        repo.write_file('test', 'test')
        repo.commit('test', message: 'test commit')
      end
    end

    context 'master branch' do
      it 'returns true if fast-forward' do
        in_repo_path do
          expect(described_class.ready?).to be true
        end
      end
    end

    context 'master branch' do
      it 'returns false if non fast-forward' do
        st = double('st', success?: false)

        expect(Open3).to receive(:capture3).with('git rev-parse --abbrev-ref HEAD').and_call_original
        expect(Open3).to receive(:capture3).with('git pull --ff-only').and_return(['', 'error', st])

        in_repo_path do
          expect { described_class.ready? }.to raise_error(ScriptError)
        end
      end
    end

    context 'different branch' do
      it 'returns false' do
        ensure_branch_exists('new-branch')

        in_repo_path do
          expect(described_class.ready?).to be false
        end
      end
    end
  end

  def ensure_branch_exists(branch)
    repo.ensure_branch_exists(branch)
  end

  def in_repo_path
    Dir.chdir(repo_path) do
      yield
    end
  end
end
