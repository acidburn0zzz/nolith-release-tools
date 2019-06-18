# frozen_string_literal: true

module ReleaseTools
  module Project
    class Gitaly < BaseProject
      REMOTES = {
        dev: 'git@dev.gitlab.org:gitlab/gitaly.git',
        gitlab: 'git@gitlab.com:gitlab-org/gitaly.git'
      }.freeze
    end
  end
end
