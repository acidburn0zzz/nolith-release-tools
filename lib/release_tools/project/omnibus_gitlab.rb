# frozen_string_literal: true

module ReleaseTools
  module Project
    class OmnibusGitlab < BaseProject
      REMOTES = {
        canonical: 'git@gitlab.com:gitlab-org/omnibus-gitlab.git',
        dev:       'git@dev.gitlab.org:gitlab/omnibus-gitlab.git',
        security:  'git@gitlab.com:gitlab-org/security/omnibus-gitlab.git'
      }.freeze
    end
  end
end
