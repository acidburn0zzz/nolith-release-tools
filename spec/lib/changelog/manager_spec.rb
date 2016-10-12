require 'spec_helper'

require 'changelog/manager'
require 'version'

describe Changelog::Manager do
  let(:fixture)    { File.expand_path('../../fixtures/repositories/changelog', __dir__) }
  let(:repository) { Rugged::Repository.new(fixture) }

  describe 'initialize' do
    it 'accepts a path String' do
      manager = described_class.new(fixture)

      expect(manager.repository).to be_kind_of(Rugged::Repository)
    end

    it 'accepts a Rugged::Repository object' do
      manager = described_class.new(repository)

      expect(manager.repository).to eq repository
    end

    it 'raises an error for any other object' do
      expect { described_class.new(StringIO.new) }.to raise_error(RuntimeError)
    end
  end

  describe '#release', 'for CE' do
    let(:release) { Version.new('8.10.5') }

    let(:changelog_file)  { 'CHANGELOG.md' }
    let(:unreleased_path) { 'changelogs/unreleased/' }

    describe 'on stable' do
      before do
        reset_fixture!

        described_class.new(repository).release(release)

        repository.checkout(release.stable_branch)
      end

      it 'removes released changelog YAML files' do
        commit = repository.last_commit
        tree   = commit.tree

        expect(changelog_blobs(tree, path: unreleased_path)).to be_empty
      end

      it 'adds a sensible commit message' do
        commit = repository.last_commit

        expect(commit.message).to eq("Update #{changelog_file} for #{release}\n\n[ci skip]")
      end

      it 'commits the updated Markdown file' do
        patch = patch_for_file(changelog_file)
        delta = patch.delta

        expect(patch.additions).to eq 4
        expect(delta).to be_modified
      end

      it 'commits the removal of the YAML files' do
        file = File.join(unreleased_path, 'fix-cycle-analytics-commits.yml')
        patch = patch_for_file(file)
        delta = patch.delta

        expect(patch.deletions).to eq 3
        expect(delta).to be_deleted
      end
    end

    describe 'on master' do
      before do
        reset_fixture!

        described_class.new(repository).release(release)

        repository.checkout('master')
      end

      it 'removes released changelog YAML files' do
        commit = repository.last_commit
        tree   = commit.tree

        blob_names = changelog_blobs(tree, path: unreleased_path)
          .map { |blob| blob[:name] }

        # Verify fix-cycle-analytics-commits.yml was removed
        expect(blob_names).to contain_exactly('group-specific-lfs.yml')
      end

      it 'adds a sensible commit message' do
        commit = repository.last_commit

        expect(commit.message).to eq("Update #{changelog_file} for #{release}\n\n[ci skip]")
      end

      it 'commits the updated Markdown file' do
        patch = patch_for_file(changelog_file)
        delta = patch.delta

        expect(patch.additions).to eq 4
        expect(delta).to be_modified
      end

      it 'commits the removal of the YAML files' do
        file = File.join(unreleased_path, 'fix-cycle-analytics-commits.yml')
        patch = patch_for_file(file)
        delta = patch.delta

        expect(patch.deletions).to eq 3
        expect(delta).to be_deleted
      end
    end
  end

  xdescribe '#release', 'for EE' do
    let(:release) { Version.new('8.10.5-ee') }

    let(:changelog_file)  { 'CHANGELOG-EE.md' }
    let(:unreleased_path) { 'CHANGES/unreleased-ee/' }

    describe 'on stable' do
      before do
        reset_fixture!

        described_class.new(repository).release(release, master_branch: 'master-ee')

        repository.checkout(release.stable_branch)
      end

      it 'removes released changelog YAML files' do
        commit = repository.last_commit
        tree   = commit.tree

        expect(changelog_blobs(tree, path: unreleased_path).map { |blob| blob[:name] })
          .to be_empty
      end

      it 'adds a sensible commit message' do
        commit = repository.last_commit

        expect(commit.message).to eq("Update #{changelog_file} for #{release}\n\n[ci skip]")
      end

      it 'commits the updated Markdown file' do
        patch = patch_for_file("#{changelog_file}")

        expect(patch.additions).to eq 4
      end

      it 'commits the removal of the YAML files' do
        file = File.join(unreleased_path, "ee-bugfix-for-cherry-picking.yml")
        patch = patch_for_file(file)

        expect(patch.deletions).to eq 3
      end
    end

    describe 'on master' do
      before do
        reset_fixture!

        described_class.new(repository).release(release, master_branch: 'master-ee')

        repository.checkout('master-ee')
      end

      it 'removes released changelog YAML files' do
        commit = repository.last_commit
        tree   = commit.tree

        expect(changelog_blobs(tree, path: unreleased_path).map { |blob| blob[:name] })
          .to match_array(%w(improve-ee-docs.yml))
      end

      it 'adds a sensible commit message' do
        commit = repository.last_commit

        expect(commit.message).to eq("Update #{changelog_file} for #{release}\n\n[ci skip]")
      end

      it 'commits the updated Markdown file' do
        patch = patch_for_file(changelog_file)

        expect(patch.additions).to eq 4
      end

      it 'commits the removal of the YAML files' do
        file = File.join(unreleased_path, "ee-bugfix-for-cherry-picking.yml")
        patch = patch_for_file(file)

        expect(patch.deletions).to eq 3
      end
    end
  end

  def reset_fixture!
    ChangelogFixture.new.rebuild_fixture!
  end

  def patch_for_file(filename, commit: repository.last_commit)
    diff = commit.diff(reverse: true)
    patches = diff.patches

    patches.reject! { |p| p.changes.zero? }
    patch = patches.detect do |p|
      p.delta.old_file[:path] == filename
    end

    patch || fail("Could not find patch file for #{filename}")
  end

  def changelog_blobs(tree, path:)
    files = []

    tree.walk_blobs do |root, entry|
      next unless root.start_with?(path)
      next if entry[:name] == '.gitkeep'

      files << entry
    end

    files
  end
end
