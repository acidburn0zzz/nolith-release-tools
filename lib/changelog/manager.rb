require 'rugged'

require_relative 'blob'
require_relative 'markdown_generator'
require_relative 'updater'

module Changelog
  # Markdown file containing all changelog entries
  CHANGELOG_FILE = 'CHANGELOG.md'

  # Folder containing unreleased changelog entries in YAML format
  UNRELEASED_PATH = 'CHANGES/unreleased/'

  class Manager
    attr_reader :repository, :version
    attr_reader :ref, :commit, :tree

    def initialize(repository)
      @repository = repository
    end

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
        message: "Prepare changelog for #{version}\n\n[ci skip]",
        parents: [commit],
        update_ref: 'HEAD'
      })

      repository.checkout_head(strategy: :force)
    end

    def checkout(branch_name)
      @ref    = repository.checkout(branch_name)
      @commit = @ref.target.target
      @tree   = @commit.tree
    end

    def remove_unreleased_blobs(index)
      index.remove_all(unreleased_blobs.collect(&:path))
    end

    def update_changelog(index)
      # Rugged points to the '.git' folder, so go up one level
      changelog_path = File.expand_path(File.join(repository.path, '..', CHANGELOG_FILE))

      updater = Updater.new(changelog_path, version)
      updater.write(MarkdownGenerator.new(version, unreleased_blobs))

      index.add(CHANGELOG_FILE)
    end

    def unreleased_blobs
      unless defined?(@unreleased_blobs)
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
      end

      @unreleased_blobs
    end
  end
end
