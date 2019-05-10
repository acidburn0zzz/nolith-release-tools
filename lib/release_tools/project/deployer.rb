# frozen_string_literal: true

module ReleaseTools
  module Project
    class Deployer < BaseProject
      REMOTES = {
        gitlab: 'git@ops.gitlab.net:gitlab-com/gl-infra/deployer.git'
      }.freeze
    end
  end
end
