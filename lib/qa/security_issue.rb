require_relative 'presenters'

module Qa
  class SecurityIssue < ::Qa::Issue
    def confidential?
      true
    end

    def title
      "#{version} Security QA Issue"
    end

    def labels
      super << ',security'
    end

    protected

    def issue_presenter
      Qa::Presenters::SecurityIssuePresenter.new(merge_requests, self, version)
    end
  end
end
