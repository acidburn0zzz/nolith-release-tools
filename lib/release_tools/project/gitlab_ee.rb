# frozen_string_literal: true

module ReleaseTools
  module Project
    class GitlabEe < BaseProject
      REMOTES = {
        dev: 'git@dev.gitlab.org:gitlab/gitlab-ee.git',
        gitlab: 'git@gitlab.com:gitlab-org/gitlab-ee.git'
      }.freeze
    end
  end
end
