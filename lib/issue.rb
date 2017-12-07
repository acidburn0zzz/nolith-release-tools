require_relative 'issuable'
require_relative 'gitlab_client'

class Issue < Issuable
  def create
    GitlabClient.create_issue(self, project)
  end

  def remote_issuable
    @remote_issuable ||= GitlabClient.find_issue(self, project)
  end

  def confidential?
    false
  end
end
