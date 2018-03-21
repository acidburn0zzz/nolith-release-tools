require_relative 'issue'
require_relative 'release'

class MonthlyIssue < Issue
  def title
    "Release #{version.to_minor}"
  end

  def labels
    'Release'
  end

  protected

  def template_path
    File.expand_path('../templates/monthly.md.erb', __dir__)
  end
end
