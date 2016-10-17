require 'spec_helper'

require 'changelog/config'
require 'changelog/manager'
require 'version'

describe Changelog::Manager do
  include RuggedMatchers

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
    let(:config)  { Changelog::Config }
    let(:release) { Version.new('8.10.5') }

    let(:changelog_file)  { config.ce_log }
    let(:unreleased_path) { config.ce_path }

    describe 'on stable' do
      before do
        reset_fixture!

        described_class.new(repository).release(release)

        repository.checkout(release.stable_branch)
      end

      it 'updates the changelog file' do
        expect(repository.last_commit).to have_modified(changelog_file)
      end

      it 'removes only the changelog files picked into stable' do
        picked   = File.join(unreleased_path, 'fix-cycle-analytics-commits.yml')
        unpicked = File.join(unreleased_path, 'group-specific-lfs.yml')

        commit = repository.last_commit

        aggregate_failures do
          expect(commit).to have_deleted(picked)
          expect(commit).not_to have_deleted(unpicked)
        end
      end

      it 'adds a sensible commit message' do
        expect(repository.last_commit.message)
          .to eq("Update #{changelog_file} for #{release}\n\n[ci skip]")
      end
    end

    describe 'on master' do
      before do
        reset_fixture!

        described_class.new(repository).release(release)

        repository.checkout('master')
      end

      it 'updates the changelog file' do
        expect(repository.last_commit).to have_modified(changelog_file)
      end

      it 'removes only the changelog files picked into stable' do
        picked   = File.join(unreleased_path, 'fix-cycle-analytics-commits.yml')
        unpicked = File.join(unreleased_path, 'group-specific-lfs.yml')

        commit = repository.last_commit

        aggregate_failures do
          expect(commit).to have_deleted(picked)
          expect(commit).not_to have_deleted(unpicked)
        end
      end

      it 'adds a sensible commit message' do
        expect(repository.last_commit.message)
          .to eq("Update #{changelog_file} for #{release}\n\n[ci skip]")
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
      next unless root == "#{path}/"
      next unless entry[:name].end_with?(Changelog::Config.extension)

      files << entry
    end

    files
  end
end
