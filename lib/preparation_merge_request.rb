require_relative 'merge_request'
require_relative 'omnibus_gitlab_version'
require_relative 'branch'

class PreparationMergeRequest < MergeRequest
  def title
    "WIP: Prepare #{full_patch_or_rc_version} release"
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

  def main_release_issue_url
    @main_release_issue_url ||= main_release_issue.url
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

  def full_patch_or_rc_version
    if version.rc?
      "#{version.to_minor} RC#{version.rc}#{ee_title_suffix}"
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

  def repo_ce_or_ee
    ee? ? 'ee' : 'ce'
  end

  def create_branch!
    Branch.new(name: source_branch, project: default_project).create(ref: stable_branch)
  rescue Gitlab::Error::BadRequest # 400 Branch already exists
    nil
  end

  protected

  def ee_title_suffix
    version.ee? ? ' EE' : ''
  end

  def main_release_issue
    if version.patch.zero?
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
