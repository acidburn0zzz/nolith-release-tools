require 'fileutils'
require 'rugged'

require_relative 'repository_fixture'

# Builds a fixture repository used in testing Changelog auto-generation
# functionality
class ChangelogFixture
  include RepositoryFixture

  def self.repository_name
    'changelog'
  end

  def build_fixture(options = {})
    build_master

    branches = {}
    merges   = {}

    # These branches have no entries
    branches['8-2-stable']    = build_stable_branch(ReleaseTools::Version.new('8.2.0'))
    branches['8-2-stable-ee'] = build_stable_branch(ReleaseTools::Version.new('8.2.0-ee'))

    # These branches have CE entries but not EE entries
    branches['8-3-stable']    = build_stable_branch(ReleaseTools::Version.new('8.3.0'))
    branches['8-3-stable-ee'] = build_stable_branch(ReleaseTools::Version.new('8.3.0-ee'))

    # These branches have CE entries and EE entries
    branches['8-10-stable']    = build_stable_branch(ReleaseTools::Version.new('8.10.0'))
    branches['8-10-stable-ee'] = build_stable_branch(ReleaseTools::Version.new('8.10.0-ee'))

    # Merge some changelog entries into `master` that will be cherry-picked
    merges['feature'] = merge_branch_with_changelog_entry(
      changelog_path: config.ce_path,
      changelog_name: 'group-specific-lfs'
    )
    merges['bugfix'] = merge_branch_with_changelog_entry(
      changelog_path: config.ce_path,
      changelog_name: 'fix-cycle-analytics-commits'
    )
    merges['ee'] = merge_branch_with_changelog_entry(
      changelog_path: config.ee_paths[0],
      changelog_name: 'protect-branch-missing-param'
    )
    merges['ee-legacy'] = merge_branch_with_changelog_entry(
      changelog_path: config.ee_paths[1],
      changelog_name: 'refactor-application-controller'
    )

    cherry_pick_to_branch(branches['8-3-stable'],     sha: merges['bugfix'])
    cherry_pick_to_branch(branches['8-3-stable-ee'],  sha: merges['bugfix'])

    cherry_pick_to_branch(branches['8-10-stable'],    sha: merges['bugfix'])
    cherry_pick_to_branch(branches['8-10-stable-ee'], sha: merges['bugfix'])
    cherry_pick_to_branch(branches['8-10-stable-ee'], sha: merges['ee'])
    cherry_pick_to_branch(branches['8-10-stable-ee'], sha: merges['ee-legacy'])

    repository.checkout('master')
  end

  private

  def config
    ReleaseTools::Changelog::Config
  end

  # Set up initial `master` state
  def build_master
    # Add CE and EE changelogs
    # NOTE: The contents of the EE changelog don't matter, so we can reuse CE's
    commit_blob(
      path: config.ce_log,
      content: read_fixture(config.ce_log),
      message: "Add basic #{config.ce_log}"
    )
    commit_blob(
      path: config.ee_log,
      content: read_fixture(config.ce_log),
      message: "Add basic #{config.ee_log}"
    )

    # Add a VERSION file containing `8.10.0-pre`
    # NOTE: This can safely be reused for CE and EE
    commit_blob(
      path: 'VERSION',
      content: "8.10.0-pre\n",
      message: "Update VERSION to 8.10.0-pre"
    )

    # Add the changelog blob structure
    commit_blob(
      path: File.join(config.ce_path, '.gitkeep'),
      content: '',
      message: "Add #{File.join(config.ce_path, '.gitkeep')}"
    )

    config.ee_paths.each do |ee_path|
      commit_blob(
        path: File.join(ee_path, '.gitkeep'),
        content: '',
        message: "Add #{File.join(ee_path, '.gitkeep')}"
      )
    end
  end

  # "Release" a version by creating its stable branch off of `master`
  #
  # Returns the Rugged::Branch object for the stable branch
  def build_stable_branch(version)
    branch = repository.branches.create(version.stable_branch, 'HEAD')

    repository.checkout(branch.name)

    # Update VERSION and commit
    commit_blob(
      path: 'VERSION',
      content: "#{version}\n",
      message: "Update VERSION to #{version}"
    )

    branch
  end

  # Create a branch and merge it to `master`, then delete the branch
  #
  # changelog_path - The configured changelog path
  # changelog_name - The changelog filename (without extension)
  #
  # The `changelog_name` will be used to read a fixture of the same name (plus
  # extension) and commit a blob with its contents before merging into `master`.
  #
  # Returns the resulting Rugged::Branch object
  def merge_branch_with_changelog_entry(changelog_path:, changelog_name:)
    repository.checkout('master')

    # Create a feature branch off of master
    branch = repository.branches.create(changelog_name, 'HEAD')
    repository.checkout(branch.name)

    fixture = read_fixture("#{changelog_name}#{config.extension}")
    entry   = load_fixture(fixture)

    # Commit the changelog entry
    commit_blob(
      path: File.join(changelog_path, "#{changelog_name}#{config.extension}"),
      content: fixture,
      message: entry['title']
    )

    # Merge branch into master
    merge_commit = merge(branch.name, 'master', message: <<~MSG)
      Merge branch '#{branch.name}' into 'master'

      #{entry['title']}

      See merge request !#{entry['id']}
    MSG

    # Delete the merged branch
    repository.checkout('master')
    repository.branches.delete(branch.name)

    merge_commit
  end

  # cherry-pick a merge commit by its SHA into a specified branch
  def cherry_pick_to_branch(branch, sha:)
    repository.checkout(branch.name)

    # cherry-pick the merge commit
    commit = repository.lookup(sha)
    target = repository.head.target
    pick_index = repository.cherrypick_commit(commit, target, 1)

    # Commit the pick
    Rugged::Commit.create(
      repository,
      tree: pick_index.write_tree(repository),
      message: commit.message,
      parents: [target],
      update_ref: 'HEAD'
    )

    repository.checkout_head(strategy: :force)
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

  def load_fixture(contents)
    YAML.safe_load(contents)
  end
end
