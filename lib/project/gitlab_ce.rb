require_relative 'base_project'

module Project
  class GitlabCe < BaseProject
    REMOTES = {
      dev: 'git@dev.gitlab.org:gitlab/gitlabhq.git',
      gitlab: 'git@gitlab.com:gitlab-org/gitlab-ce.git',
      github: 'git@github.com:gitlabhq/gitlabhq.git'
    }.freeze

    def self.path
      "#{group}/gitlab-ce"
    end
  end
end
