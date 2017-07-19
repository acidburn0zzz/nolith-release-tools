require_relative 'project/gitlab_ce'
require_relative 'project/gitlab_ee'

class GitlabClient
  class MissingMilestone
    def id
      nil
    end
  end

  def self.current_user
    @current_user ||= Gitlab.user
  end

  def self.issues(project = Project::GitlabCe, options = {})
    client.issues(project.path, options)
  end

  def self.merge_requests(project = Project::GitlabCe, options = {})
    client.merge_requests(project.path, options)
  end

  def self.milestones(project = Project::GitlabCe, options = {})
    client.milestones(project.path, options)
  end

  def self.milestone(project = Project::GitlabCe, title:)
    milestones(project.path)
      .detect { |m| m.title == title } || MissingMilestone.new
  end

  # Create an issue in the CE project based on the provided issue
  #
  # issue - An object that responds to the following messages:
  #   :title       - Issue title String
  #   :description - Issue description String
  #   :labels      - Comma-separated String of label names
  #   :version     - Version object
  # project - An object that responds to :path
  #
  # The issue is always assigned to the authenticated user.
  #
  # Returns a Gitlab::ObjectifiedHash object
  def self.create_issue(issue, project = Project::GitlabCe)
    milestone = milestone(project, title: issue.version.milestone_name)

    client.create_issue(project.path, issue.title,
      description:  issue.description,
      assignee_id:  current_user.id,
      milestone_id: milestone.id,
      labels: issue.labels,
      confidential: issue.confidential?)
  end

  # Create a merge request in the given project based on the provided merge request
  #
  # merge_request - An object that responds to the following messages:
  #   :title       - Merge request title String
  #   :description - Merge request description String
  #   :labels      - Comma-separated String of label names
  #   :source_branch - The source branch
  #   :target_branch - The target branch
  # project - An object that responds to :path
  #
  # The merge request is always assigned to the authenticated user.
  #
  # Returns a Gitlab::ObjectifiedHash object
  def self.create_merge_request(merge_request, project = Project::GitlabCe)
    client.create_merge_request(
      project.path,
      merge_request.title,
      description:   merge_request.description,
      assignee_id:   current_user.id,
      labels:        merge_request.labels,
      source_branch: merge_request.source_branch,
      target_branch: merge_request.target_branch || 'master')
  end

  # Find an issue in the given project based on the provided issue
  #
  # issue - An object that responds to the following messages:
  #   :title  - Issue title String
  #   :labels - Comma-separated String of label names
  # project - An object that responds to :path
  #
  # Returns a Gitlab::ObjectifiedHash object, or nil
  def self.find_issue(issue, project = Project::GitlabCe)
    opts = {
      labels: issue.labels,
      milestone: issue.version.milestone_name
    }

    issues(project, opts).detect { |i| i.title == issue.title }
  end

  # Find an open merge request in the given project based on the provided merge request
  #
  # merge_request - An object that responds to the following messages:
  #   :title  - Merge request title String
  #   :labels - Comma-separated String of label names
  # project - An object that responds to :path
  #
  # Returns a Gitlab::ObjectifiedHash object, or nil
  def self.find_merge_request(merge_request, project = Project::GitlabCe)
    opts = {
      labels: merge_request.labels,
      state: 'opened'
    }

    merge_requests(project, opts)
      .detect { |i| i.title == merge_request.title }
  end

  # Returns the URL of an issue in the given project based on the provided issue
  #
  # issue - An object that responds to the following messages:
  #   :iid - Issue IID String
  # project - An object that responds to :path
  #
  # Returns an URL
  def self.issue_url(issue, project = Project::GitlabCe)
    return '' if issue.iid.nil?

    "https://gitlab.com/#{project.path}/issues/#{issue.iid}"
  end

  # Returns the URL of a merge request in the given project based on the provided merge request
  #
  # merge_request - An object that responds to the following messages:
  #   :iid - Merge request IID String
  # project - An object that responds to :path
  #
  # Returns an URL
  def self.merge_request_url(merge_request, project = Project::GitlabCe)
    return '' if merge_request.iid.nil?

    "https://gitlab.com/#{project.path}/merge_requests/#{merge_request.iid}"
  end

  def self.client
    @client ||= Gitlab.client(endpoint: ENV['GITLAB_API_ENDPOINT'], private_token: ENV['GITLAB_API_PRIVATE_TOKEN'])
  end

  private_class_method :client
end
