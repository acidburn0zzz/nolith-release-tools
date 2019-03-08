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

    PERMITTED_WITH_TEAM_LABELS = [
      'Documentation'
    ].freeze

    UNPERMITTED_LABELS = [
      'Quality',
      'meta',
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
