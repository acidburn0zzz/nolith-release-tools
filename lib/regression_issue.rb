require_relative 'base_issue'

class RegressionIssue < BaseIssue
  attr_reader :version

  def initialize(version)
    @version = version
  end

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
