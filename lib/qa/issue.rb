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

    protected

    def template_path
      File.expand_path('../../templates/qa.md.erb', __dir__)
    end

    def issue_presenter
      Qa::Presenters::QaIssuePresenter.new(merge_requests, remote_issuable, version)
    end

    def comment_presenter
      Qa::Presenters::QaCommentPresenter.new(merge_requests)
    end
  end
end
