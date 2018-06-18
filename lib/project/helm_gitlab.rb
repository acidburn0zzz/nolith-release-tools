require_relative 'base_project'

module Project
  class HelmGitlab < BaseProject
    REMOTES = {
      gitlab: 'git@gitlab.com:charts/gitlab.git',
    }.freeze

    def self.path
      "#{group}/gitlab"
    end

    def self.group
      'charts'
    end
  end
end
