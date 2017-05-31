require_relative 'merge_request'

class UpstreamMergeRequest < MergeRequest
  PROJECT = Project::GitlabEe
  LABELS = 'CE upstream'.freeze

  def self.open_mrs
    GitlabClient
      .merge_requests(PROJECT, labels: LABELS, state: 'opened')
      .select { |mr| mr.target_branch == 'master' }
  end

  def project
    PROJECT
  end

  def title
    @title ||= "CE upstream - #{Date.today.strftime('%A')}"
  end

  def labels
    LABELS
  end

  def source_branch
    @source_branch ||= "ce-to-ee-#{Date.today.iso8601}"
  end
end
