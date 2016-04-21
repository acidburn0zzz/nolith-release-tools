require 'dotenv'
require 'gitlab'

# Load ENV and then reset Gitlab client so it actually picks up our config
Dotenv.load
Gitlab.reset

class GitlabClient
  class MissingMilestone
    def id
      nil
    end
  end

  # Hard-code the CE project ID to save a request
  CE_PROJECT_ID = 13_083

  def self.current_user
    @current_user ||= Gitlab.user
  end

  def self.ce_issues(options = {})
    Gitlab.issues(CE_PROJECT_ID, options)
  end

  def self.ce_milestones(options = {})
    Gitlab.milestones(CE_PROJECT_ID, options)
  end

  def self.ce_milestone(title)
    ce_milestones.
      detect { |m| m.title == title } || MissingMilestone.new
  end

  # Create an issue in the CE project based on the provided issue
  #
  # issue - An object that responds to the following messages:
  #         :title       - Issue title String
  #         :description - Issue description String
  #         :labels      - Comma-separated String of label names
  #         :version     - Version object
  #
  # The issue is always assigned to the authenticated user.
  #
  # Returns a Gitlab::ObjectifiedHash object
  def self.create_issue(issue)
    milestone = ce_milestone(issue.version.milestone_name)

    Gitlab.create_issue(CE_PROJECT_ID, issue.title, {
      description:  issue.description,
      assignee_id:  current_user.id,
      milestone_id: milestone.id,
      labels:       issue.labels
    })
  end

  # Find an issue in the CE project based on the provided issue
  #
  # issue - An object that responds to the following messages:
  #         :title  - Issue title String
  #         :labels - Comma-separated String of label names
  #
  # Returns a Gitlab::ObjectifiedHash object, or nil
  def self.find_issue(issue)
    opts = { labels: issue.labels, milestone: issue.version.milestone_name }

    ce_issues(opts).detect { |i| i.title == issue.title }
  end

  def self.issue_url(issue)
    "https://gitlab.com/gitlab-org/gitlab-ce/issues/#{issue.iid}"
  end
end
