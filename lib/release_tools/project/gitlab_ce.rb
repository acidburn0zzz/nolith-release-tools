# frozen_string_literal: true

module ReleaseTools
  module Project
    class GitlabCe < BaseProject
      REMOTES = {
        dev: 'git@dev.gitlab.org:balasankarc/gitlabhq.git',
        gitlab: 'git@gitlab.com:balasankarc/gitlab-ce.git'
      }.freeze
    end
  end
end
