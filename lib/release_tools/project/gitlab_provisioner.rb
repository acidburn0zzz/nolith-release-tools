# frozen_string_literal: true

module ReleaseTools
  module Project
    class GitlabProvisioner < BaseProject
      REMOTES = {
        gitlab: 'git@gitlab.com:gitlab-org/distribution/gitlab-provisioner.git'
      }.freeze
    end
  end
end
