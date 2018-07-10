require_relative 'base_project'

module Project
  class OmnibusGitlab < BaseProject
    REMOTES = {
      dev: 'git@dev.gitlab.org:gitlab/omnibus-gitlab.git',
      gitlab: 'git@gitlab.com:gitlab-org/omnibus-gitlab.git'
    }.freeze
  end
end
