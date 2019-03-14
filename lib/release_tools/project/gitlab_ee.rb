# frozen_string_literal: true

module ReleaseTools
  module Project
    class GitlabEe < BaseProject
      REMOTES = {
        dev: 'git@dev.gitlab.org:balasankarc/gitlab-ee.git',
        gitlab: 'git@gitlab.com:balasankarc/gitlab-ee.git'
      }.freeze
    end
  end
end
