# frozen_string_literal: true

module ReleaseTools
  class GitlabClient
    DEFAULT_GITLAB_API_ENDPOINT = 'https://gitlab.com/api/v4'

    # Some methods get delegated directly to the internal client
    class << self
      extend Forwardable

      def_delegator :client, :commits
      def_delegator :client, :pipelines
      def_delegator :client, :pipeline_jobs
      def_delegator :client, :job_play

      def_delegator :client, :create_merge_request_comment
      def_delegator :client, :create_group_label
    end

    class MissingMilestone
      def id
        nil
      end
    end

    def self.current_user
      @current_user ||= client.user
    end

    def self.issues(project = Project::GitlabCe, options = {})
      client.issues(project_path(project), options)
    end

    def self.merge_requests(project = Project::GitlabCe, options = {})
      client.merge_requests(project_path(project), options)
    end

    def self.merge_request(project = Project::GitlabCe, iid:)
      client.merge_request(project_path(project), iid)
    end

    def self.merge_request_approvals(project = Project::GitlabCe, iid:)
      client.merge_request_approvals(project_path(project), iid)
    end

    def self.pipeline(project = Project::GitlabCe, id)
      client.pipeline(project_path(project), id)
    end

    def self.run_trigger(project = Project::GitlabCe, token, ref, options)
      client.run_trigger(project_path(project), token, ref, options)
    end

    def self.commit_merge_requests(project = Project::GitlabCe, sha:)
      client.commit_merge_requests(project_path(project), sha)
    end

    def self.compare(project = Project::GitlabCe, from:, to:)
      client.compare(project_path(project), from, to)
    end

    def self.commit(project = Project::GitlabCe, ref:)
      client.commit(project_path(project), ref)
    end

    def self.create_issue_note(project = Project::GitlabCe, issue:, body:)
      client.create_issue_note(project_path(project), issue.iid, body)
    end

    def self.close_issue(project = Project::GitlabCe, issue)
      client.close_issue(project_path(project), issue.iid)
    end

    def self.milestones(project = Project::GitlabCe, options = {})
      project_milestones = client.milestones(project_path(project), options)
      group_milestones = client.group_milestones('gitlab-org', options)

      project_milestones + group_milestones
    end

    def self.current_milestone
      current = milestones(Project::GitlabCe, state: 'active')
        .select { |m| current_milestone?(m) }
        .max_by(&:due_date)

      current || MissingMilestone.new
    end

    def self.milestone(project = Project::GitlabCe, title:)
      return MissingMilestone.new if title.nil?

      milestones(project)
        .detect { |m| m.title == title } || raise("Milestone #{title} not found for project #{project_path(project)}!")
    end

    # Create an issue in the CE project based on the provided issue
    #
    # issue - An object that responds to the following messages:
    #   :title       - Issue title String
    #   :description - Issue description String
    #   :labels      - Comma-separated String of label names
    #   :version     - Version object
    #   :assignees   - An Array of user IDs to use as the assignees.
    # project - An object that responds to :path
    #
    # The issue is always assigned to the authenticated user.
    #
    # Returns a Gitlab::ObjectifiedHash object
    def self.create_issue(issue, project = Project::GitlabCe)
      milestone = milestone(project, title: issue.version.milestone_name)

      assignees =
        if issue.respond_to?(:assignees)
          issue.assignees
        else
          [current_user.id]
        end

      client.create_issue(
        project_path(project),
        issue.title,
        description: issue.description,
        assignee_ids: assignees,
        milestone_id: milestone.id,
        labels: issue.labels,
        confidential: issue.confidential?
      )
    end

    # Update an issue in the CE project based on the provided issue
    #
    # issue - An object that responds to the following messages:
    #   :title       - Issue title String
    #   :description - Issue description String
    #   :labels      - Comma-separated String of label names
    # project - An object that responds to :path
    #
    # The issue is always assigned to the authenticated user.
    #
    # Returns a Gitlab::ObjectifiedHash object
    def self.update_issue(issue, project = Project::GitlabCe)
      milestone = milestone(project, title: issue.version.milestone_name)

      client.edit_issue(
        project_path(project),
        issue.iid,
        description: issue.description,
        milestone_id: milestone.id,
        labels: issue.labels,
        confidential: issue.confidential?
      )
    end

    # Link an issue as related to another
    #
    # issue - An Issuable object
    # target - An Issuable object
    def self.link_issues(issue, target)
      # NOTE: The GitLab gem doesn't currently support this API
      path = client.url_encode(project_path(issue.project))

      # NOTE: `target_project_id` parameter doesn't support encoded values
      #   See https://gitlab.com/gitlab-org/gitlab-ee/issues/9143
      client.post(
        "/projects/#{path}/issues/#{issue.iid}/links", query: {
          target_project_id: project_path(target.project),
          target_issue_iid: target.iid
        }
      )
    end

    # Create a branch with the given name
    #
    # branch_name - Name of the new branch
    # ref - commit sha or existing branch ref
    # project - An object that responds to :path
    #
    # Returns a Gitlab::ObjectifiedHash object
    def self.create_branch(branch_name, ref, project = Project::GitlabCe)
      client.create_branch(project_path(project), branch_name, ref)
    end

    # Find a branch in a given project
    #
    # Returns a Gitlab::ObjectifiedHash object, or nil
    def self.find_branch(branch_name, project = Project::GitlabCe)
      client.branch(project_path(project), branch_name)
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
      milestone =
        if merge_request.milestone.nil?
          current_milestone
        else
          milestone(project, title: merge_request.milestone)
        end

      params = {
        description: merge_request.description,
        assignee_id: current_user.id,
        labels: merge_request.labels,
        source_branch: merge_request.source_branch,
        target_branch: merge_request.target_branch,
        milestone_id: milestone.id,
        remove_source_branch: true
      }

      client.create_merge_request(project_path(project), merge_request.title, params)
    end

    # Accept a merge request in the given project specified by the iid
    #
    # merge_request - An object that responds to the following message:
    #   :iid  - Internal id of merge request
    # project - An object that responds to :path
    #
    # Returns a Gitlab::ObjectifiedHash object
    def self.accept_merge_request(merge_request, project = Project::GitlabCe)
      params = {
        merge_when_pipeline_succeeds: true
      }
      client.accept_merge_request(project_path(project), merge_request.iid, params)
    end

    # Approve a merge request in the given project
    #
    # Because an author cannot approve their own MRs, we use a client with the
    # `GITLAB_API_APPROVAL_TOKEN` value when the author is the current user.
    def self.approve_merge_request(merge_request, project = Project::GitlabCe)
      approval = lambda do |client|
        client.approve_merge_request(project_path(project), merge_request.iid)
      end

      if merge_request.author&.id == current_user.id
        approval.call(approval_client)
      else
        approval.call(client)
      end
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
        milestone: issue.version.milestone_name,
        search: issue.title
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

    def self.cherry_pick(project = Project::GitlabCe, ref:, target:)
      # NOTE: The GitLab gem doesn't currently support this API
      path = CGI.escape(project_path(project))

      client.post(
        "/projects/#{path}/repository/commits/#{ref}/cherry_pick",
        query: { branch: target }
      )
    end

    def self.client
      @client ||= Gitlab.client(
        endpoint: DEFAULT_GITLAB_API_ENDPOINT,
        private_token: ENV['GITLAB_API_PRIVATE_TOKEN']
      )
    end
    private_class_method :client

    def self.approval_client
      @approval_client ||= Gitlab.client(
        endpoint: DEFAULT_GITLAB_API_ENDPOINT,
        private_token: ENV['GITLAB_API_APPROVAL_TOKEN']
      )
    end
    private_class_method :approval_client

    # Overriden by GitLabDevClient
    def self.project_path(project)
      project.path
    end

    def self.current_milestone?(milestone)
      return false if milestone.start_date.nil?
      return false if milestone.due_date.nil?

      Date.parse(milestone.start_date) <= Date.today &&
        Date.parse(milestone.due_date) >= Date.today
    end
  end
end
