# frozen_string_literal: true

module ReleaseTools
  module Project
    class OmnibusGitlab < BaseProject
      REMOTES = {
        dev: 'git@dev.gitlab.org:balasankarc/omnibus-gitlab.git',
        gitlab: 'git@gitlab.com:balasankarc/omnibus-gitlab.git'
      }.freeze
    end
  end
end
