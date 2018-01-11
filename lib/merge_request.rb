require_relative 'issuable'
require_relative 'gitlab_client'

class MergeRequest < Issuable
  def milestone
    self[:milestone] || nil
  end

  def source_branch
    self[:source_branch] || raise(ArgumentError, 'Please set a `source_branch`!')
  end

  def target_branch
    self[:target_branch] || 'master'
  end

  def create
    GitlabClient.create_merge_request(self, project)
  end

  def remote_issuable
    @remote_issuable ||= GitlabClient.find_merge_request(self, project)
  end
end
