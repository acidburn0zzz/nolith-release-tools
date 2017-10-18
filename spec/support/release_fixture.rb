require 'fileutils'
require 'rugged'

require_relative 'repository_fixture'

class ReleaseFixture
  include RepositoryFixture

  def self.repository_name
    'release'
  end

  def build_fixture(options = {})
    commit_blob(
      path:    'README.md',
      content: 'Sample README.md',
      message: 'Add empty README.md'
    )
    commit_version_blobs(
      'GITLAB_SHELL_VERSION'     => "2.2.2\n",
      'GITLAB_WORKHORSE_VERSION' => "3.3.3\n",
      'GITALY_SERVER_VERSION'    => "5.5.5\n",
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
      'GITALY_SERVER_VERSION'    => "5.6.0\n",
      'GITLAB_PAGES_VERSION'     => "4.5.0\n",
      'GITLAB_SHELL_VERSION'     => "2.3.0\n",
      'GITLAB_WORKHORSE_VERSION' => "3.4.0\n",
      'VERSION'                  => "1.2.0\n"
    )

    repository.checkout('master')
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

  def build_fixture(options = {})
    @repository = Rugged::Repository.init_at(fixture_path)

    commit_blob(path: 'README.md', content: '', message: 'Add empty README.md')
    commit_version_blobs(
      'GITLAB_SHELL_VERSION'     => "2.2.2\n",
      'GITLAB_WORKHORSE_VERSION' => "3.3.3\n",
      'GITALY_SERVER_VERSION'    => "5.5.5\n",
      'VERSION'                  => "1.9.24\n"
    )

    commit_blob(
      path: 'docker/openshift-template.json',
      content: '"name": "gitlab-1.9.24","name": "gitlab/gitlab-ce:1.9.24-ce.0","name": "${APPLICATION_NAME}:gitlab-1.9.24"',
      message: 'Add openshift-template.json'
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

if $PROGRAM_NAME == __FILE__
  puts "Building release fixture..."
  ReleaseFixture.new.rebuild_fixture!

  puts "Building omnibus release fixture..."
  OmnibusReleaseFixture.new.rebuild_fixture!
end
