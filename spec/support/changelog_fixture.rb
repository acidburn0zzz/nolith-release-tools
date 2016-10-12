require 'fileutils'
require 'rugged'

require 'changelog/config'

# Builds a fixture repository used in testing Changelog auto-generation
# functionality
class ChangelogFixture
  attr_reader :fixture_path, :repository

  def initialize(fixture_path = nil)
    @fixture_path = fixture_path || default_fixture_path
  end

  def rebuild_fixture!
    wipe_fixture!
    build_fixture
  end

  def wipe_fixture!
    FileUtils.rm_r(fixture_path) if Dir.exist?(fixture_path)
    FileUtils.mkdir_p(fixture_path)
  end

  def build_fixture
    @repository = Rugged::Repository.init_at(fixture_path)

    build_master
    stable_branch = build_stable_branch

    build_feature_branch
    bugfix_branch = build_bugfix_branch

    merge_commit = merge_bugfix_branch(bugfix_branch)
    cherry_pick_to_branch(stable_branch, sha: merge_commit)

    repository.checkout('master')
  end

  private

  def config
    Changelog::Config
  end

  def default_fixture_path
    File.expand_path("../fixtures/repositories/changelog", __dir__)
  end

  # Set up initial `master` state
  def build_master
    # Add a CHANGELOG.md file with example version headers and entries
    commit_blob(
      path: config.ce_log,
      content: read_fixture(config.ce_log),
      message: "Add basic #{config.ce_log}"
    )

    # Add a VERSION file containing `8.10.0-pre`
    commit_blob(
      path: 'VERSION',
      content: '8.10.0-pre',
      message: "Update VERSION to 8.10.0-pre"
    )

    # Add the changelog blob structure
    commit_blob(
      path: File.join(config.ce_path, '.gitkeep'),
      content: '',
      message: "Add #{File.join(config.ce_path, '.gitkeep')}"
    )
  end

  # Create a feature branch and merge it to `master`, then delete the branch
  #
  # Returns the resulting Rugged::Branch object
  def build_feature_branch(feature_name: 'group-specific-lfs')
    repository.checkout('master')

    # Create a feature branch off of master
    feature_branch = repository.branches.create(feature_name, 'HEAD')
    repository.checkout(feature_branch.name)

    # Commit the changelog entry
    commit_blob(
      path: File.join(config.ce_path, "#{feature_name}#{config.extension}"),
      content: read_fixture("#{feature_name}#{config.extension}"),
      message: "Added group-specific settings for LFS."
    )

    # Merge feature branch into master
    repository.checkout('master')
    merge(
      feature_branch.name,
      'master',
      message: "Merge branch '#{feature_branch.name}' into 'master'\n\nSee merge request !6164"
    )

    # Delete the merged branch
    repository.branches.delete(feature_branch.name)

    feature_branch
  end

  # "Release" 8.10 by branching `8-10-stable` off of `master`
  #
  # Returns the Rugged::Branch object for the stable branch
  def build_stable_branch
    stable_branch = repository.branches.create('8-10-stable', 'HEAD')
    repository.checkout(stable_branch.name)

    # Update VERSION and commit
    commit_blob(
      path: 'VERSION',
      content: '8.10.0',
      message: 'Update VERSION to 8.10.0'
    )

    stable_branch
  end

  # Create a bug fix branch and merge it to `master`
  #
  # Returns the resulting Rugged::Branch object
  def build_bugfix_branch(bugfix_name: 'fix-cycle-analytics-commits')
    repository.checkout('master')

    # Create a bugfix branch off of master
    bugfix_branch = repository.branches.create(bugfix_name, 'HEAD')
    repository.checkout(bugfix_branch.name)

    # Commit the changelog entry
    commit_blob(
      path: File.join(config.ce_path, "#{bugfix_name}#{config.extension}"),
      content: read_fixture("#{bugfix_name}#{config.extension}"),
      message: 'Fix an issue with the "Commits" section of the cycle analytics summary.'
    )

    bugfix_branch
  end

  # Merge `source_branch` into `master`
  #
  # Returns a merge commit SHA
  def merge_bugfix_branch(source_branch)
    # Merge into master
    repository.checkout('master')
    merge_commit = merge(source_branch.name, 'master', {
      message: "Merge branch '#{source_branch.name}' into 'master'\n\nSee merge request !6164"
    })

    # Delete the merged branch
    repository.branches.delete(source_branch.name)

    merge_commit
  end

  # cherry-pick a merge commit by its SHA into a specified branch
  def cherry_pick_to_branch(branch, sha:)
    repository.checkout(branch.name)

    # cherry-pick the merge commit
    merge_commit = repository.lookup(sha)
    pick_index = repository.cherrypick_commit(
      merge_commit,
      repository.head.target,
      1
    )

    # Commit the pick
    Rugged::Commit.create(
      repository,
      tree: pick_index.write_tree(repository),
      message: merge_commit.message,
      parents: [repository.head.target],
      update_ref: 'HEAD'
    )

    repository.checkout_head(strategy: :force)
  end

  def commit_blob(path:, content:, message:)
    index = repository.index

    oid = repository.write(content, :blob)
    index.add(path: path, oid: oid, mode: 0100644)

    commit = Rugged::Commit.create(repository, {
      tree: index.write_tree(repository),
      message: message,
      parents: repository.empty? ? [] : [ repository.head.target ].compact,
      update_ref: 'HEAD'
    })

    repository.checkout_head(strategy: :force)

    commit
  end

  # Copy-pasta from gitlab_git
  def merge(source_name, target_name, options = {})
    our_commit = repository.branches[target_name].target
    their_commit = repository.branches[source_name].target

    raise "Invalid merge target" if our_commit.nil?
    raise "Invalid merge source" if their_commit.nil?

    merge_index = repository.merge_commits(our_commit, their_commit)
    return false if merge_index.conflicts?

    actual_options = options.merge(
      parents: [our_commit, their_commit],
      tree: merge_index.write_tree(repository),
      update_ref: "refs/heads/#{target_name}"
    )
    commit = Rugged::Commit.create(repository, actual_options)

    # 'cept this
    repository.checkout_head(strategy: :force)

    commit
  end

  def read_fixture(filename)
    File.read(File.expand_path("../fixtures/changelog/#{filename}", __dir__))
  end
end
