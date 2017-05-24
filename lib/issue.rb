require_relative 'issuable'
require_relative 'gitlab_client'

class Issue < Issuable
  def create
    GitlabClient.create_issue(self)
  end

  def remote_issuable
    GitlabClient.find_issue(self)
  end

  def confidential?
    false
  end

  private

  def _url
    GitlabClient.issue_url(remote_issuable)
  end
end
