require_relative 'base_project'

module Project
  class OmnibusGitlab < BaseProject
    REMOTES = {
      dev: 'git@dev.gitlab.org:gitlab/omnibus-gitlab.git',
      gitlab: 'git@gitlab.com:gitlab-org/omnibus-gitlab.git',
      github: 'git@github.com:gitlabhq/omnibus-gitlab.git'
    }.freeze

    def self.path
      'gitlab-org/omnibus-gitlab'
    end
  end
end
