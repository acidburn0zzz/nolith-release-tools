# frozen_string_literal: true

module ReleaseTools
  module Project
    class GitlabCe < BaseProject
      REMOTES = {
        dev: 'git@dev.gitlab.org:gitlab/gitlabhq.git',
        gitlab: 'git@gitlab.com:gitlab-org/gitlab-foss.git'
      }.freeze
    end
  end
end
