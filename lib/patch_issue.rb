require_relative 'base_issue'
require_relative 'regression_issue'

class PatchIssue < BaseIssue
  attr_reader :version

  def initialize(version)
    @version = version
  end

  def title
    "Release #{version.to_patch}"
  end

  def labels
    'Release'
  end

  def regression_issue
    @regression_issue ||= RegressionIssue.new(version)
  end

  protected

  def template_path
    File.expand_path('../templates/patch.md.erb', __dir__)
  end
end
