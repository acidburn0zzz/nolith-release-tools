require_relative 'issuable'
require_relative 'gitlab_client'

class MergeRequest < Issuable
  def create
    GitlabClient.create_merge_request(self, project)
  end

  def remote_issuable
    return @remote_issuable if defined?(@remote_issuable)

    @remote_issuable ||= GitlabClient.find_merge_request(self, project)
  end

  def url
    GitlabClient.merge_request_url(self, project)
  end
end
