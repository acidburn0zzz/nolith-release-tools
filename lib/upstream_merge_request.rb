require_relative 'commit_author'
require_relative 'merge_request'

class UpstreamMergeRequest < MergeRequest
  PROJECT = Project::GitlabEe
  LABELS = 'CE upstream'.freeze
  UPSTREAM_MR_DESCRIPTION = <<~DESCRIPTION.freeze
    Try to resolve one file per commit, and then push (no force-push!) to the `%s` branch.

    Thanks in advance! ❤️

    Note: This merge request was created by an automated script.
    Please report any issue at https://gitlab.com/gitlab-org/release-tools/issues!
  DESCRIPTION

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

  def description
    if conflicts_data.empty?
      'Congrats, no conflicts!'
    else
      description = conflicts_data.reduce("Files to resolve:\n") do |text, conflict|
        username = CommitAuthor.new(conflict[:user]).to_gitlab(reference: true)
        username = "`#{username}`" unless self[:mention_people]

        text << "\n" << conflict_checklist_item(user: username, file: conflict[:path], conflict_type: conflict[:conflict_type])
      end
      description << "\n\n" << (UPSTREAM_MR_DESCRIPTION % source_branch)
    end
  end

  def labels
    LABELS
  end

  def source_branch
    self[:source_branch] || "ce-to-ee-#{Date.today.iso8601}"
  end

  private

  def conflicts_data
    self[:conflicts_data] || []
  end

  def conflict_checklist_item(user:, file:, conflict_type:)
    "- [ ] #{user} Please resolve https://gitlab.com/gitlab-org/gitlab-ee/blob/#{source_branch}/#{file} (#{conflict_type})"
  end
end
