require 'rugged'

require_relative 'blob'
require_relative 'markdown_generator'
require_relative 'updater'

module Changelog
  # Manager collects the unreleased changelog entries in a Version's stable
  # branch, converts them into Markdown, removes the individual files from both
  # the stable and master branches, and updates the global CHANGELOG Markdown
  # file with the changelog for that version.
  class Manager
    attr_reader :repository, :version
    attr_reader :ref, :commit, :tree, :index

    # repository - Rugged::Repository object or String path to repository
    def initialize(repository)
      case repository
      when String
        @repository = Rugged::Repository.new(repository)
      when Rugged::Repository
        @repository = repository
      else
        raise "Invalid repository: #{repository}"
      end
    end

    # Given a Version, this method will perform the following actions on both
    # that version's respective `stable` branch and on `master`:
    #
    # 1. Collect a list of YAML files in `unreleased_path`
    # 2. Remove them from the repository
    # 3. Compile their contents into Markdown
    # 4. Update `changelog_file` with the compiled Markdown
    # 5. Commit
    def release(version, master_branch: 'master')
      @version = version

      perform_release(version.stable_branch)
      perform_release(master_branch)
    end

    private

    def changelog_file
      @changelog_file ||=
        if version.ee?
          'CHANGELOG-EE.md'
        else
          'CHANGELOG.md'
        end
    end

    def unreleased_path
      @unreleased_path ||=
        if version.ee?
          'changelogs/unreleased-ee/'
        else
          'changelogs/unreleased/'
        end
    end

    def perform_release(branch_name)
      checkout(branch_name)

      remove_unreleased_blobs
      update_changelog

      create_commit
    end

    # Checkout the specified branch and update `ref`, `commit`, `tree`, and
    # `index` with the current state of the repository.
    #
    # branch_name - Branch name to checkout
    def checkout(branch_name)
      @ref    = repository.checkout(branch_name)
      @commit = @ref.target.target
      @tree   = @commit.tree
      @index  = repository.index

      @index.read_tree(commit.tree)
    end

    def remove_unreleased_blobs
      index.remove_all(unreleased_blobs.collect(&:path))
    end

    # Updates CHANGELOG_FILE with the Markdown built from the individual
    # unreleased changelog entries.
    def update_changelog
      blob = repository.blob_at(repository.head.target_id, changelog_file)
      updater = Updater.new(blob.content, version)

      changelog_oid = repository.write(updater.insert(generate_markdown), :blob)
      index.add(path: changelog_file, oid: changelog_oid, mode: 0100644)
    end

    def generate_markdown
      MarkdownGenerator.new(version, unreleased_blobs).to_s
    end

    def create_commit
      Rugged::Commit.create(repository, {
        tree: index.write_tree(repository),
        message: "Update #{changelog_file} for #{version}\n\n[ci skip]",
        parents: [commit],
        update_ref: 'HEAD'
      })

      repository.checkout_head(strategy: :force)
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
        next unless root == unreleased_path
        next unless entry[:name].end_with?('.yml')

        @unreleased_blobs << Blob.new(
          File.join(root, entry[:name]),
          repository.lookup(entry[:oid])
        )
      end

      @unreleased_blobs
    end

    def on_stable?
      repository.head.canonical_name.end_with?('-stable')#, 'stable-ee')
    end
  end
end
