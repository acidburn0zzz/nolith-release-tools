# frozen_string_literal: true

module ReleaseTools
  module Project
    class GitlabPages < BaseProject
      REMOTES = {
        dev: 'git@dev.gitlab.org:gitlab/gitlab-pages.git',
        gitlab: 'git@gitlab.com:gitlab-org/gitlab-pages.git'
      }.freeze
    end
  end
end
