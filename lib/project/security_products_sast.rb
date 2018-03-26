require_relative 'base_project'

module Project
  class SecurityProductsSast < BaseProject
    REMOTES = {
      gitlab: 'git@gitlab.com:gitlab-org/security-products/sast.git'
    }.freeze

    def self.path
      "#{group}/security-products/sast"
    end
  end
end
