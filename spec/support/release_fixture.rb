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

    # At some point we release Pages!
    commit_blobs('GITLAB_PAGES_VERSION' => "4.4.4\n")

    # Create new stable branches
    repository.branches.create('9-1-stable',    'HEAD')
    repository.branches.create('9-1-stable-ee', 'HEAD')

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

class CNGImageReleaseFixture
  include RepositoryFixture

  def self.repository_name
    'cng-image-release'
  end

  def build_fixture(options = {})
    variables_file = <<~MSG
      variables:
        GITLAB_VERSION: "master"
        GITLAB_REF_SLUG: "master"
        GITLAB_ASSETS_TAG: "master"
        GITLAB_SHELL_VERSION: "master"
        GITLAB_WORKHORSE_VERSION: "master"
        GITALY_VERSION: "master"
        GIT_VERSION: "2.18.1"
        GO_VERSION: "1.9.6"
        KUBECTL_VERSION: "v1.9.3"
        PG_VERSION: "9.6.8"
        MAILROOM_VERSION: "0.9.0"
        ALPINE_VERSION: "3.8"
        CFSSL_VERSION: "1.2"
        DOCKER_DRIVER: overlay2
        DOCKER_HOST: tcp://docker:2375
        ASSETS_IMAGE_PREFIX: "gitlab-assets"
        ASSETS_IMAGE_REGISTRY_PREFIX: "registry.gitlab.com/gitlab-org"
        COMPILE_ASSETS: "false"
        S3CMD_VERSION: "2.0.1"
        PYTHON_VERSION: "3.4.9"
    MSG
    commit_blob(path: 'ci_files/variables.yml', content: variables_file, message: 'Add variables file')
    commit_blob(path: 'README.md', content: '', message: 'Add empty README.md')
    repository.branches.create('9-1-stable',    'HEAD')
    repository.branches.create('9-1-stable-ee', 'HEAD')
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
    repository.tags.create('v0.2.7', 'HEAD')

    chart_data = <<~EOS
      apiVersion: v1
      name: gitlab
      version: 0.3.0
      appVersion: 11.1.0
    EOS

    commit_blob(path: 'Chart.yaml', content: chart_data, message: 'Update chart yaml')

    repository.branches.create('0-3-stable', 'HEAD')
    repository.tags.create('v0.3.0', 'HEAD')

    # Bump the versions in master
    chart_data = <<~EOS
      apiVersion: v1
      name: gitlab
      version: 0.3.0
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
