require_relative 'base_project'

module Project
  class GitlabCiYml < BaseProject
    REMOTES = {
      gitlab: 'git@gitlab.com:gitlab-org/gitlab-ci-yml.git'
    }.freeze

    def self.path
      "#{group}/gitlab-ci-yml"
    end
  end
end
