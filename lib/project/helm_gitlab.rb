require_relative 'base_project'

module Project
  class HelmGitlab < BaseProject
    REMOTES = {
      gitlab: 'git@gitlab.com:charts/gitlab.git',
    }.freeze
  end
end
