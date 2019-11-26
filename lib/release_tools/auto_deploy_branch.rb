# frozen_string_literal: true

module ReleaseTools
  # Represents an auto-deploy branch for purposes of cherry-picking
  class AutoDeployBranch
    attr_reader :version
    attr_reader :branch_name

    # Return the current auto-deploy branch name from environment variable
    def self.current
      ENV.fetch('AUTO_DEPLOY_BRANCH')
    end

    def initialize(version, branch_name)
      @version = version
      @branch_name = branch_name
    end

    def exists?
      true
    end

    def to_s
      branch_name
    end

    # Included in cherry-pick summary messages
    def pick_destination
      "`#{branch_name}`"
    end

    def release_issue
      ReleaseTools::MonthlyIssue.new(version: version)
    end
  end
end
