require_relative 'issue'
require_relative 'omnibus_gitlab_version'

class PatchIssue < Issue
  def omnibus_version
    @omnibus_version ||= OmnibusGitlabVersion.new(version.to_omnibus(ee: version.ee?))
  end

  def title
    "Release #{version.to_patch}"
  end

  def labels
    'Release'
  end

  protected

  def template_path
    File.expand_path('../templates/patch.md.erb', __dir__)
  end
end
