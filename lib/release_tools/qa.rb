# frozen_string_literal: true

module ReleaseTools
  module Qa
    TEAM_LABELS = [
      'Community contribution',
      'Plan',
      'Platform',
      'Create',
      'Manage',
      'Verify',
      'Release',
      'Geo',
      'Gitaly',
      'Package',
      'Configure',
      'Monitor',
      'Secure',
      'frontend',
      'database'
    ].freeze

    UNPERMITTED_LABELS = [
      'Quality',
      'meta',
      'Documentation',
      'test',
      'broken master',
      'CE upstream',
      'Delivery',
      'development guidelines',
      'static analysis',
      'QA',
      'rails5'
    ].freeze

    PROJECTS = [
      ReleaseTools::Project::GitlabEe
    ].freeze

    ISSUE_PROJECT = ReleaseTools::Project::Release::Tasks
  end
end
