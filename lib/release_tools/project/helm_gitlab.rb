# frozen_string_literal: true

module ReleaseTools
  module Project
    class HelmGitlab < BaseProject
      REMOTES = {
        dev: 'git@dev.gitlab.org:balasankarc/gitlab.git',
        gitlab: 'git@gitlab.com:balasankarc/gitlab.git',
      }.freeze
    end
  end
end
