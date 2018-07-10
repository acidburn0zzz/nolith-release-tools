require_relative 'base_project'

module Project
  class GitlabEe < BaseProject
    REMOTES = {
      dev: 'git@dev.gitlab.org:gitlab/gitlab-ee.git',
      gitlab: 'git@gitlab.com:gitlab-org/gitlab-ee.git'
    }.freeze
  end
end
