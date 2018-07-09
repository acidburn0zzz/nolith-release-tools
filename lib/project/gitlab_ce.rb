require_relative 'base_project'

module Project
  class GitlabCe < BaseProject
    REMOTES = {
      dev: 'git@dev.gitlab.org:gitlab/gitlabhq.git',
      gitlab: 'git@gitlab.com:gitlab-org/gitlab-ce.git'
    }.freeze
  end
end
