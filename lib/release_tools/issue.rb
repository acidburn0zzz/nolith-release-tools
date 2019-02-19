# frozen_string_literal: true

module ReleaseTools
  class Issue < Issuable
    def create
      GitlabClient.create_issue(self, project)
    end

    def update
      GitlabClient.update_issue(self, project)
    end

    def remote_issuable
      @remote_issuable ||= GitlabClient.find_issue(self, project)
    end

    def confidential?
      false
    end
  end
end
