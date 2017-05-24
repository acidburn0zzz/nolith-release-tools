require_relative 'issuable'
require_relative 'gitlab_client'

class MergeRequest < Issuable
  attr_accessor :project, :title, :description, :labels, :source_branch, :target_branch

  def initialize
    yield self if block_given?
  end

  def create
    GitlabClient.create_merge_request(self, project)
  end

  def remote_issuable
    GitlabClient.find_merge_request(self, project)
  end

  private

  def _url
    GitlabClient.merge_request_url(remote_issuable, project)
  end
end
