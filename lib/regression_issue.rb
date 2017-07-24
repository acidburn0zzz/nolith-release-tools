require_relative 'issue'

class RegressionIssue < Issue
  def title
    "#{version.to_minor} Regressions"
  end

  def labels
    'Release'
  end

  protected

  def template_path
    File.expand_path('../templates/regression.md.erb', __dir__)
  end
end
