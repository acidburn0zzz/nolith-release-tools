# frozen_string_literal: true

module ReleaseTools
  module Project
    class Gitaly < BaseProject
      REMOTES = {
        canonical: 'git@gitlab.com:gitlab-org/gitaly.git',
        dev:       'git@dev.gitlab.org:gitlab/gitaly.git'
      }.freeze
    end
  end
end
