require 'fileutils'
require 'rugged'

module RepositoryFixture
  def rebuild_fixture!
    wipe_fixture!
    build_fixture
  end

  def wipe_fixture!
    FileUtils.rm_r(fixture_path) if Dir.exist?(fixture_path)
    FileUtils.mkdir_p(fixture_path)
  end

  private

  # Commit multiple `VERSION`-type files at once
  #
  # files - A Hash of filename => content pairs
  #
  # Returns the Rugged::Commit object
  def commit_version_blobs(files)
    index = repository.index

    files.each do |path, content|
      oid = repository.write(content, :blob)
      index.add(path: path, oid: oid, mode: 0o100644)
    end

    message = "Add #{files.keys.join(', ')}"

    commit = Rugged::Commit.create(repository, {
      tree: index.write_tree(repository),
      message: message,
      parents: repository.empty? ? [] : [repository.head.target].compact,
      update_ref: 'HEAD'
    })

    repository.checkout_head(strategy: :force)

    commit
  end

  def commit_blob(path:, content:, message:)
    index = repository.index

    oid = repository.write(content, :blob)
    index.add(path: path, oid: oid, mode: 0o100644)

    commit = Rugged::Commit.create(repository, {
      tree: index.write_tree(repository),
      message: message,
      parents: repository.empty? ? [] : [repository.head.target].compact,
      update_ref: 'HEAD'
    })

    repository.checkout_head(strategy: :force)

    commit
  end

  def default_fixture_path
    File.expand_path(
      "../fixtures/repositories/#{self.class.repository_name}",
      __dir__
    )
  end
end

class ReleaseFixture
  include RepositoryFixture

  def self.repository_name
    'release'
  end

  attr_reader :fixture_path, :repository

  def initialize(fixture_path = nil)
    @fixture_path = fixture_path || default_fixture_path
  end

  def build_fixture
    @repository = Rugged::Repository.init_at(fixture_path)

    commit_blob(
      path:    'README.md',
      content: 'Sample README.md',
      message: 'Add empty README.md'
    )
    commit_version_blobs(
      'GITLAB_SHELL_VERSION'     => "2.2.2\n",
      'GITLAB_WORKHORSE_VERSION' => "3.3.3\n",
      'VERSION'                  => "1.1.1\n"
    )

    repository.checkout('master')

    # Create a basic branch
    repository.branches.create('branch-1', 'HEAD')

    # Create old stable branches
    repository.branches.create('1-9-stable',    'HEAD')
    repository.branches.create('1-9-stable-ee', 'HEAD')

    # At some point we release Pages!
    commit_version_blobs('GITLAB_PAGES_VERSION' => "4.4.4\n")

    # Create new stable branches
    repository.branches.create('9-1-stable',    'HEAD')
    repository.branches.create('9-1-stable-ee', 'HEAD')

    # Bump the versions in master
    commit_version_blobs(
      'GITLAB_PAGES_VERSION'     => "4.5.0\n",
      'GITLAB_SHELL_VERSION'     => "2.3.0\n",
      'GITLAB_WORKHORSE_VERSION' => "3.4.0\n",
      'VERSION'                  => "1.2.0\n"
    )
  end
end

class OmnibusReleaseFixture
  include RepositoryFixture

  def self.repository_name
    'omnibus-release'
  end

  attr_reader :fixture_path, :repository

  def initialize(fixture_path = nil)
    @fixture_path = fixture_path || default_fixture_path
  end

  def build_fixture
    @repository = Rugged::Repository.init_at(fixture_path)

    commit_blob(path: 'README.md', content: '', message: 'Add empty README.md')
    commit_version_blobs(
      'GITLAB_SHELL_VERSION'     => "2.2.2\n",
      'GITLAB_WORKHORSE_VERSION' => "3.3.3\n",
      'VERSION'                  => "1.9.24\n"
    )

    repository.branches.create('1-9-stable',    'HEAD')
    repository.branches.create('1-9-stable-ee', 'HEAD')

    commit_version_blobs(
      'GITLAB_PAGES_VERSION'     => "master\n",
      'GITLAB_SHELL_VERSION'     => "2.2.2\n",
      'GITLAB_WORKHORSE_VERSION' => "3.3.3\n",
      'VERSION'                  => "1.9.24\n"
    )

    repository.branches.create('9-1-stable',    'HEAD')
    repository.branches.create('9-1-stable-ee', 'HEAD')

    # Bump the versions in master
    commit_version_blobs(
      'GITLAB_PAGES_VERSION'     => "master\n",
      'GITLAB_SHELL_VERSION'     => "master\n",
      'GITLAB_WORKHORSE_VERSION' => "master\n",
      'VERSION'                  => "master\n"
    )
  end
end

if __FILE__ == $0
  puts "Building release fixture..."
  ReleaseFixture.new.rebuild_fixture!

  puts "Building omnibus release fixture..."
  OmnibusReleaseFixture.new.rebuild_fixture!
end
