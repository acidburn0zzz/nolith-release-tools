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
    'Packaging',
    'Configure',
    'Monitoring',
    'Secure',
    'frontend',
    'database'
  ].freeze

  TYPE_LABELS = [
    'bug',
    'feature proposal',
    'regression',
    'Deliverable'
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
    Project::GitlabEe
  ].freeze

  ISSUE_PROJECT = Project::Release::Tasks
end
