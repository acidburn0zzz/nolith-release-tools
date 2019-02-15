require_relative 'issue'
require_relative 'omnibus_gitlab_version'

class PatchIssue < Issue
  def omnibus_version
    @omnibus_version ||= OmnibusGitlabVersion.new(version.to_omnibus(ee: version.ee?))
  end

  def title
    "Release #{version.to_ce}"
  end

  def labels
    'Monthly Release'
  end

  def project
    ::Project::Release::Tasks
  end

  def monthly_issue
    @monthly_issue ||= MonthlyIssue.new(version: version)
  end

  def link!
    return if version.monthly?

    GitlabClient.link_issues(self, monthly_issue)
  end

  def assignees
    monthly_issue.assignees
  end

  protected

  def template_path
    if version.rc?
      File.expand_path('../templates/release_candidate.md.erb', __dir__)
    else
      File.expand_path('../templates/patch.md.erb', __dir__)
    end
  end
end
