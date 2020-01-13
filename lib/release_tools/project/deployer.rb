# frozen_string_literal: true

module ReleaseTools
  module Project
    class Deployer < BaseProject
      REMOTES = {
        canonical: 'git@ops.gitlab.net:gitlab-com/gl-infra/deployer.git'
      }.freeze

      # we don't make distinctions of remotes for projects on ops
      def self.to_s
        path
      end
    end
  end
end
