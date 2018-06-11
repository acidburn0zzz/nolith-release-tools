require_relative 'project/release_tasks'

module Qa
  TEAM_LABELS = [
    'Discussion',
    'Platform',
    'CI/CD',
    'Geo',
    'Gitaly',
    'Monitoring',
    'Security Products',
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
    'QA'
  ].freeze

  PROJECTS = [
    Project::GitlabEe
  ].freeze

  ISSUE_PROJECT = Project::ReleaseTasks
end
