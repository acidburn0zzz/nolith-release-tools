require 'spec_helper'

require 'changelog/manager'
require 'version'

describe Changelog::Manager do
  let(:release)    { Version.new('8.10.5') }
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

  describe 'on stable' do
    before do
      reset_fixture!

      Timecop.freeze(Time.local(1983, 7, 2))
      Changelog::Manager.new(repository).release(release)

      repository.checkout(release.stable_branch)
    end

    it 'removes changelog YAML files' do
      commit = repository.last_commit
      tree   = commit.tree

      expect(changelog_blobs(tree).map { |blob| blob[:name] })
        .to match_array(%W(.gitkeep #{Changelog::CHANGELOG_FILE}))
    end

    it 'compiles changelog YAML files into a single Markdown file' do
      entry    = changelog_blob("#{Changelog::CHANGELOG_FILE}", tree: repository.last_commit.tree)
      blob     = repository.lookup(entry[:oid])
      markdown = blob.content

      expect(markdown).to include("## #{release} (1983-07-02)")
      expect(markdown).to include("- This fixes a bug and needs to go into stable. !2")
    end

    it 'adds a sensible commit message' do
      commit = repository.last_commit

      expect(commit.message).to eq("Update changelog for #{release}\n\n[ci skip]")
    end

    it 'commits the updated Markdown file' do
      patch = patch_for_file("#{Changelog::CHANGELOG_FILE}")

      expect(patch.additions).to eq 4
    end

    it 'commits the removal of the YAML files' do
      patch = patch_for_file("#{Changelog::UNRELEASED_PATH}bugfix-for-cherry-picking.yml")

      expect(patch.deletions).to eq 3
    end
  end

  describe 'on master' do
    before do
      reset_fixture!

      Timecop.freeze(Time.local(1983, 7, 2))
      Changelog::Manager.new(repository).release(release)

      repository.checkout('master')
    end

    it 'removes changelog YAML files' do
      commit = repository.last_commit
      tree   = commit.tree

      expect(changelog_blobs(tree).map { |blob| blob[:name] })
        .to match_array(%W(.gitkeep #{Changelog::CHANGELOG_FILE} feature-a.yml feature-b.yml))
    end

    it 'compiles changelog YAML files into a single Markdown file' do
      entry    = changelog_blob("#{Changelog::CHANGELOG_FILE}", tree: repository.last_commit.tree)
      blob     = repository.lookup(entry[:oid])
      markdown = blob.content

      expect(markdown).to include("## #{release} (1983-07-02)")
      expect(markdown).to include("- This fixes a bug and needs to go into stable. !2")
    end

    it 'adds a sensible commit message' do
      commit = repository.last_commit

      expect(commit.message).to eq("Update changelog for #{release}\n\n[ci skip]")
    end

    it 'commits the updated Markdown file' do
      patch = patch_for_file("#{Changelog::CHANGELOG_FILE}")

      expect(patch.additions).to eq 4
    end

    it 'commits the removal of the YAML files' do
      patch = patch_for_file("#{Changelog::UNRELEASED_PATH}bugfix-for-cherry-picking.yml")

      expect(patch.deletions).to eq 3
    end
  end

  def reset_fixture!
    %W(master #{release.stable_branch}).each do |branch|
      repository.checkout(branch)
      repository.reset("upstream/#{branch}", :hard)
    end
  end

  def patch_for_file(filename, commit: repository.last_commit)
    diff = commit.diff(reverse: true)
    patches = diff.patches

    patches.reject! { |p| p.changes.zero? }
    patch = patches.detect do |p|
      p.delta.old_file[:path] == filename
    end

    fail "Could not find patch file for #{filename}" unless patch

    patch
  end

  def changelog_blob(filename, tree:)
    changelog_blobs(tree).detect { |entry| entry[:name] == filename }
  end

  def changelog_blobs(tree)
    files = []

    tree.walk_blobs do |root, entry|
      next unless root.start_with?(Changelog::UNRELEASED_PATH) ||
        entry[:name] == Changelog::CHANGELOG_FILE

      files << entry
    end

    files
  end
end
