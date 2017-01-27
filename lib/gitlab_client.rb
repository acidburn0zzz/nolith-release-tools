require 'gitlab'

class GitlabClient
  class MissingMilestone
    def id
      nil
    end
  end

  # Hard-code IDs following the 'namespace%2Frepo' pattern
  CE_PROJECT_ID = 'gitlab-org%2Fgitlab-ce'.freeze

  class << self
    def current_user
      @current_user ||= Gitlab.user
    end

    def ce_issues(options = {})
      client.issues(CE_PROJECT_ID, options)
    end

    def ce_milestones(options = {})
      client.milestones(CE_PROJECT_ID, options)
    end

    def ce_milestone(title)
      ce_milestones
      .detect { |m| m.title == title } || MissingMilestone.new
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
    def create_issue(issue)
      milestone = ce_milestone(issue.version.milestone_name)

      client.create_issue(CE_PROJECT_ID, issue.title, {
        description:  issue.description,
        assignee_id:  current_user.id,
        milestone_id: milestone.id,
        labels:       issue.labels,
        confidential: issue.confidential?
      })
    end

    # Find an issue in the CE project based on the provided issue
    #
    # issue - An object that responds to the following messages:
    #         :title  - Issue title String
    #         :labels - Comma-separated String of label names
    #
    # Returns a Gitlab::ObjectifiedHash object, or nil
    def find_issue(issue)
      opts = { labels: issue.labels, milestone: issue.version.milestone_name }

      ce_issues(opts).detect { |i| i.title == issue.title }
    end

    def issue_url(issue)
      "https://gitlab.com/gitlab-org/gitlab-ce/issues/#{issue.iid}"
    end

    private

    def client
      @client ||= Gitlab.client(endpoint: ENV['GITLAB_API_ENDPOINT'], private_token: ENV['GITLAB_API_PRIVATE_TOKEN'])
    end
  end
end
