require 'rugged'

require_relative 'blob'
require_relative 'markdown_generator'
require_relative 'updater'

module Changelog
  # Markdown file containing all changelog entries
  CHANGELOG_FILE = 'CHANGELOG.md'

  # Folder containing unreleased changelog entries in YAML format
  UNRELEASED_PATH = 'CHANGES/unreleased/'

  # Manager collects the unreleased changelog entries in a Version's stable
  # branch, converts them into Markdown, removes the individual files from both
  # the stable and master branches, and updates the global CHANGELOG Markdown
  # file with the changelog for that version.
  class Manager
    attr_reader :repository, :version
    attr_reader :ref, :commit, :tree

    def initialize(repository)
      @repository = repository
    end

    # Given a Version, this method will perform the following actions on both
    # that version's respective `stable` branch and on `master`:
    #
    # 1. Collect a list of YAML files in `UNRELEASED_PATH`
    # 2. Remove them from the repository
    # 3. Compile their contents into Markdown
    # 4. Update `CHANGELOG_FILE` with the compiled Markdown
    # 5. Commit
    def release(version)
      @version = version

      perform_release(version.stable_branch)
      perform_release('master')
    end

    private

    def perform_release(branch_name)
      checkout(branch_name)

      index = repository.index
      index.read_tree(commit.tree)

      remove_unreleased_blobs(index)
      update_changelog(index)

      Rugged::Commit.create(repository, {
        tree: index.write_tree(repository),
        message: "Update changelog for #{version}\n\n[ci skip]",
        parents: [commit],
        update_ref: 'HEAD'
      })

      repository.checkout_head(strategy: :force)
    end

    # Checkout the specified branch name and update `ref`, `commit`, and `tree`
    # with the current state of the repository.
    #
    # branch_name - Branch name to checkout
    def checkout(branch_name)
      @ref    = repository.checkout(branch_name)
      @commit = @ref.target.target
      @tree   = @commit.tree
    end

    def remove_unreleased_blobs(index)
      index.remove_all(unreleased_blobs.collect(&:path))
    end

    # Updates CHANGELOG_FILE with the Markdown built from the individual
    # unreleased changelog entries.
    #
    # index - Current repository index
    def update_changelog(index)
      blob = repository.blob_at(repository.head.target_id, CHANGELOG_FILE)
      markdown = MarkdownGenerator.new(version, unreleased_blobs).to_s

      updater = Updater.new(blob.content, version)
      changelog_oid = repository.write(updater.insert(markdown), :blob)

      index.add(path: CHANGELOG_FILE, oid: changelog_oid, mode: 0100644)
    end

    # Build an Array of Changelog::Blob objects, with each object representing a
    # single unreleased changelog entry file.
    #
    # Raises RuntimeError if the currently-checked-out branch is not a stable
    # branch, or if the repository tree could not be read.
    #
    # Returns an Array
    def unreleased_blobs
      return @unreleased_blobs if defined?(@unreleased_blobs)

      raise "Cannot gather changelog blobs on a non-stable branch." unless on_stable?
      raise "Cannot gather changelog blobs. Check out the stable branch first!" unless tree

      @unreleased_blobs = []

      tree.walk(:preorder) do |root, entry|
        next unless root == UNRELEASED_PATH
        next if entry[:name] == '.gitkeep'

        @unreleased_blobs << Blob.new(
          File.join(root, entry[:name]),
          repository.lookup(entry[:oid])
        )
      end

      @unreleased_blobs
    end

    def on_stable?
      repository.head.canonical_name.end_with?('-stable')
    end
  end
end
