module Qa
  TEAM_LABELS = [
    'Plan',
    'Platform',
    'Create',
    'Manage',
    'CI/CD',
    'Geo',
    'Gitaly',
    'Packaging',
    'Configuration',
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
    'Release',
    'test',
    'broken master',
    'CE upstream',
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
