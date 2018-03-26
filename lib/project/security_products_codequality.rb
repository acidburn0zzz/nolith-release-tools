require_relative 'base_project'

module Project
  class SecurityProductsCodequality < BaseProject
    REMOTES = {
      gitlab: 'git@gitlab.com:gitlab-org/security-products/codequality.git'
    }.freeze

    def self.path
      "#{group}/security-products/codequality"
    end
  end
end
