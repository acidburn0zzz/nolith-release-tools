require_relative 'issue'
require_relative 'omnibus_gitlab_version'

class PatchIssue < Issue
  def omnibus_version
    @omnibus_version ||= OmnibusGitlabVersion.new(version.to_omnibus(ee: version.ee?))
  end

  def title
    "Release #{version}"
  end

  def labels
    'Release'
  end

  def project
    # TODO (rspeicher): Eventually we probably want everything in release/tasks
    # But for now let's phase this in slowly
    if version.rc?
      ::Project::Release::Tasks
    else
      super
    end
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
