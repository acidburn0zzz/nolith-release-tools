require_relative 'merge_request'
require_relative 'omnibus_gitlab_version'
require_relative 'branch'

class PreparationMergeRequest < MergeRequest
  def title
    "WIP: Prepare #{version} release"
  end

  def labels
    'Delivery'
  end

  def source_branch
    preparation_branch_name
  end

  def target_branch
    stable_branch
  end

  def release_issue_url
    @release_issue_url ||= release_issue.url
  end

  def stable_branch
    version.stable_branch
  end

  def milestone
    version.milestone_name
  end

  def patch_or_rc_version
    if version.rc?
      "RC#{version.rc}"
    else
      version.to_s
    end
  end

  def preparation_branch_name
    if version.rc?
      "#{version.stable_branch}-prepare-rc#{version.rc}"
    else
      "#{version.stable_branch}-patch-#{version.patch}"
    end
  end

  def ee?
    version.ee?
  end

  # "Link" this MR to its release issue by updating description placeholders
  def link!
    issue = release_issue.remote_issuable
    template = (ee? ? 'EE' : 'CE') << '_PREPARATION_MR_LINK'

    begin
      GitlabClient.edit_issue(
        issue.project_id,
        issue.iid,
        description: issue.description.sub("{{#{template}}}", url)
      )
    rescue Gitlab::Error => ex
      # Well we tried!
      Raven.capture_exception(ex)
    end
  end

  def create_branch!
    Branch.new(name: source_branch, project: default_project).tap do |branch|
      branch.create(ref: stable_branch) unless SharedStatus.dry_run?
    end
  rescue Gitlab::Error::BadRequest # 400 Branch already exists
    nil
  end

  protected

  def release_issue
    if version.monthly?
      MonthlyIssue.new(version: version)
    else
      PatchIssue.new(version: version)
    end
  end

  def template_path
    File.expand_path('../templates/preparation_merge_request.md.erb', __dir__)
  end

  def default_project
    if self[:version].ee?
      Project::GitlabEe
    else
      Project::GitlabCe
    end
  end
end
