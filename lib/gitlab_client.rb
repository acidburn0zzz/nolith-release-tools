require_relative 'project/gitlab_ce'
require_relative 'project/gitlab_ee'

class GitlabClient
  DEFAULT_GITLAB_API_ENDPOINT = 'https://gitlab.com/api/v4'.freeze

  class MissingMilestone
    def id
      nil
    end
  end

  def self.current_user
    @current_user ||= client.user
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
    return MissingMilestone.new if title.nil?

    milestones(project)
      .detect { |m| m.title == title } || raise("Milestone #{title} not found for project #{project.path}!")
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
    client.create_issue(project.path, issue.title,
      description:  issue.description,
      assignee_id:  current_user.id,
      labels: issue.labels,
      confidential: issue.confidential?)
  end

  # Create a branch with the given name
  #
  # branch_name - Name of the new branch
  # ref - commit sha or existing branch ref
  # project - An object that responds to :path
  #
  # Returns a Gitlab::ObjectifiedHash object
  def self.create_branch(branch_name, ref, project = Project::GitlabCe)
    client.create_branch(project.path, branch_name, ref)
  end

  # Find a branch in a given project
  #
  # Returns a Gitlab::ObjectifiedHash object, or nil
  def self.find_branch(branch_name, project = Project::GitlabCe)
    client.branch(project.path, branch_name)
  rescue Gitlab::Error::NotFound
    nil
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
    params = {
      description: merge_request.description,
      assignee_id: current_user.id,
      labels: merge_request.labels,
      source_branch: merge_request.source_branch,
      target_branch: merge_request.target_branch,
      remove_source_branch: true
    }

    client.create_merge_request(project.path, merge_request.title, params)
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
      labels: issue.labels
    }

    issues(project, opts).detect { |i| i.title == issue.title && i.milestone&.title == issue.version.milestone_name }
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
      .detect { |i| i.title == merge_request.title && i.milestone&.title == merge_request.version.milestone_name }
  end

  def self.client
    @client ||= Gitlab.client(
      endpoint: ENV.fetch('GITLAB_API_ENDPOINT', DEFAULT_GITLAB_API_ENDPOINT),
      private_token: ENV['GITLAB_API_PRIVATE_TOKEN']
    )
  end

  private_class_method :client
end
