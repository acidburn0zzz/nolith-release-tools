# frozen_string_literal: true

module ReleaseTools
  module Project
    class Deployer < BaseProject
      REMOTES = {
        ops: 'git@ops.gitlab.net:gitlab-com/gl-infra/deployer.git'
      }.freeze
      DEFAULT_REMOTE = :ops
    end
  end
end
