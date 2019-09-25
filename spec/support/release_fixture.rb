# frozen_string_literal: true

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
    commit_blobs(
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

    repository.tags.create('v1.9.0', 'HEAD', message: 'GitLab Version 1.9.0')

    # At some point we release Pages!
    commit_blobs('GITLAB_PAGES_VERSION' => "4.4.4\n")

    # Create new stable branches
    repository.branches.create('9-1-stable',    'HEAD')
    repository.branches.create('9-1-stable-ee', 'HEAD')

    repository.tags.create('v9.1.0', 'HEAD', message: 'GitLab Version 9.1.0')

    # Bump the versions in master
    commit_blobs(
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

  def build_fixture(options = {})
    commit_blob(path: 'README.md', content: '', message: 'Add empty README.md')
    commit_blobs(
      'GITLAB_SHELL_VERSION'     => "2.2.2\n",
      'GITLAB_WORKHORSE_VERSION' => "3.3.3\n",
      'GITALY_SERVER_VERSION'    => "5.5.5\n",
      'VERSION'                  => "1.9.24\n"
    )

    repository.branches.create('1-9-stable',    'HEAD')
    repository.branches.create('1-9-stable-ee', 'HEAD')

    commit_blobs(
      'GITLAB_PAGES_VERSION'     => "master\n",
      'GITLAB_SHELL_VERSION'     => "2.2.2\n",
      'GITLAB_WORKHORSE_VERSION' => "3.3.3\n",
      'VERSION'                  => "1.9.24\n"
    )

    repository.branches.create('9-1-stable',    'HEAD')
    repository.branches.create('9-1-stable-ee', 'HEAD')

    # Bump the versions in master
    commit_blobs(
      'GITLAB_PAGES_VERSION'     => "master\n",
      'GITLAB_SHELL_VERSION'     => "master\n",
      'GITLAB_WORKHORSE_VERSION' => "master\n",
      'VERSION'                  => "master\n"
    )
  end
end

class HelmReleaseFixture
  include RepositoryFixture

  def self.repository_name
    'helm-release'
  end

  def build_fixture(options = {})
    commit_blob(path: 'README.md', content: '', message: 'Add empty README.md')

    chart_data = <<~EOS
      apiVersion: v1
      name: gitlab
      version: 0.2.7
      appVersion: 11.0.5
    EOS

    commit_blob(path: 'Chart.yaml', content: chart_data, message: 'Add chart yaml')

    repository.branches.create('0-2-stable', 'HEAD')
    repository.tags.create('v0.2.7', 'HEAD', message: 'Version v0.2.7 - contains GitLab EE 11.0.5')

    # Charts bumping a major version due to breaking changes
    chart_data = <<~EOS
      apiVersion: v1
      name: gitlab
      version: 1.0.0
      appVersion: 11.2.0
    EOS

    commit_blob(path: 'Chart.yaml', content: chart_data, message: 'Update chart yaml')

    repository.branches.create('1-0-stable', 'HEAD')
    repository.tags.create('v1.0.0', 'HEAD', message: 'Version v1.0.0 - contains GitLab EE 11.2.0')

    # Bump the versions in master
    chart_data = <<~EOS
      apiVersion: v1
      name: gitlab
      version: 1.0.0
      appVersion: master
    EOS

    commit_blob(path: 'Chart.yaml', content: chart_data, message: 'Update chart yaml to master')
  end
end

if $PROGRAM_NAME == __FILE__
  puts "Building release fixture..."
  ReleaseFixture.new.rebuild_fixture!

  puts "Building omnibus release fixture..."
  OmnibusReleaseFixture.new.rebuild_fixture!
end
