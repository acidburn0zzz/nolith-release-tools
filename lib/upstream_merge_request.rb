require_relative 'commit_author'
require_relative 'merge_request'

class UpstreamMergeRequest < MergeRequest
  def self.project
    Project::GitlabEe
  end

  def self.labels
    'CE upstream'.freeze
  end

  def self.open_mrs
    GitlabClient
      .merge_requests(project, labels: labels, state: 'opened')
      .select { |mr| mr.target_branch == 'master' }
  end

  def project
    self.class.project
  end

  def labels
    self.class.labels
  end

  def title
    self[:title] ||= "CE upstream - #{Date.today.strftime('%A')}"
  end

  def description
    if conflicts.empty?
      '**Congrats, no conflicts!** :tada:'
    else
      out = StringIO.new
      out.puts("Files to resolve:\n\n")
      conflicts.each do |conflict|
        username = CommitAuthor.new(conflict[:user]).to_gitlab
        username = "`#{username}`" unless self[:mention_people]

        out.puts conflict_checklist_item(user: username, file: conflict[:path], conflict_type: conflict[:conflict_type])
      end
      out.puts
      out.puts <<~DESCRIPTION.freeze
        Try to resolve one file per commit, and then push (no force-push!) to the `#{source_branch}` branch.

        Thanks in advance! :heart:

        Note: This merge request was created by an automated script.
        Please report any issue at https://gitlab.com/gitlab-org/release-tools/issues!
      DESCRIPTION
      out.string
    end
  end

  def source_branch
    self[:source_branch] || "ce-to-ee-#{Date.today.iso8601}"
  end

  private

  def conflicts
    self[:conflicts] || []
  end

  def conflict_checklist_item(user:, file:, conflict_type:)
    "- [ ] #{user} Please resolve [(#{conflict_type}) `#{file}`](https://gitlab.com/#{project.path}/blob/#{source_branch}/#{file})"
  end
end
