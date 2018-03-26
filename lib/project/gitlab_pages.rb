require_relative 'base_project'

module Project
  class GitlabPages < BaseProject
    REMOTES = {
      dev: 'git@dev.gitlab.org:gitlab/gitlab-pages.git',
      gitlab: 'git@gitlab.com:gitlab-org/gitlab-pages.git'
    }.freeze

    def self.path
      "#{group}/gitlab-pages"
    end
  end
end
