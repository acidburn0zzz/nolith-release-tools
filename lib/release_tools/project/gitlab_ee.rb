# frozen_string_literal: true

module ReleaseTools
  module Project
    class GitlabEe < BaseProject
      REMOTES = {
        canonical: 'git@gitlab.com:gitlab-org/gitlab.git',
        dev:       'git@dev.gitlab.org:gitlab/gitlab-ee.git'
      }.freeze
    end
  end
end
