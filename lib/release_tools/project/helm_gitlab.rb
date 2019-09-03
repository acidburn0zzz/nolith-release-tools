# frozen_string_literal: true

module ReleaseTools
  module Project
    class HelmGitlab < BaseProject
      REMOTES = {
        dev: 'git@dev.gitlab.org:gitlab/charts/gitlab.git',
        gitlab: 'git@gitlab.com:gitlab-org/charts/gitlab.git'
      }.freeze
    end
  end
end
