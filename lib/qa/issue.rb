require_relative '../gitlab_client'
require_relative 'presenters'

module Qa
  class Issue < ::Issue
    def title
      "#{version} QA Issue"
    end

    def labels
      'QA task'
    end

    def add_comment
      GitlabClient.create_issue_note(project, issue: remote_issuable, body: comment_body)
    end

    def comment_body
      comment_presenter.present
    end

    def link!
      GitlabClient.link_issues(self, parent_issue)
    end

    protected

    def template_path
      File.expand_path('../../templates/qa.md.erb', __dir__)
    end

    def issue_presenter
      Qa::Presenters::IssuePresenter.new(merge_requests, self, version)
    end

    def comment_presenter
      Qa::Presenters::CommentPresenter.new(merge_requests)
    end

    def parent_issue
      ::PatchIssue.new(version: version)
    end
  end
end
