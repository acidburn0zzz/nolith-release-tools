require_relative 'issue'
require_relative 'gitlab_client'

class QaIssue < Issue
  PROJECTS_FOR_QA = [
    Project::GitlabCe,
    Project::GitlabEe,
    Project::OmnibusGitlab,
    Project::GitlabPages,
    Project::GitlabCiYml,
    Project::SecurityProductsSast,
    Project::SecurityProductsCodequality
  ].freeze

  def labels
    'Release,QA'
  end

  protected

  def template_path
    File.expand_path('../templates/qa.md.erb', __dir__)
  end

  def version_string
    version.rc? ? version.to_rc : version.to_patch
  end
end

class FirstRcQaIssue < QaIssue
  # This class aims to create an issue
  # with all changes relevant to the new release
  # and mention the author of the relevant issues

  BUG_LABELS = [
    "bug"
  ].freeze

  FEATURE_LABELS = [
    "feature proposal"
  ].freeze

  attr_reader :issues

  def title
    "First RC #{version_string} QA Issue"
  end

  def resources
    issues
  end

  private

  def issues
    @issues ||= feature_issues + bug_issues
  end

  def fetch_issues(options)
    PROJECTS_FOR_QA.map do |project|
      GitlabClient.issues(project, options).auto_paginate
    end.flatten
  end

  def feature_issues
    @feature_issues ||= fetch_issues(feature_issue_options)
  end

  def bug_issues
    @bug_issues ||= fetch_issues(bug_issue_options)
  end

  def issue_options
    {
      state: 'closed',
      milestone: version.to_minor
    }
  end

  def bug_issue_options
    issue_options.merge(labels: BUG_LABELS.join(','))
  end

  def feature_issue_options
    issue_options.merge(labels: FEATURE_LABELS.join(','))
  end
end

class RcPatchQaIssue < QaIssue
  # This class aims to create an issue with all changes relevant
  # to the new patch or RC release and mention the author of the
  # relevant MRs

  # Because this relies on the `Pick into stable` label, and
  # this label is removed once a fix is picked, the issue
  # should be generated before picking

  attr_reader :merge_requests

  def title
    "#{version_string} QA Issue"
  end

  def resources
    merge_requests
  end

  private

  def merge_requests
    @merge_requests ||= PROJECTS_FOR_QA.map do |project|
      GitlabClient.merge_requests(project, merge_request_options).auto_paginate
    end.flatten
  end

  def merge_request_options
    {
      state: 'merged',
      labels: "Pick into #{version.to_minor}"
    }
  end
end
