require_relative 'client'

class PatchIssue
  attr_reader :version

  def initialize(version)
    @version = version
  end

  def title
    "Release #{version.to_patch}"
  end

  def description
    ERB.new(template).result(binding)
  end

  def labels
    'release'
  end

  def create
    Client.create_issue(self)
  end

  def regression_issue
    @regression_issue ||= RegressionIssue.new(version)
  end

  private

  def template
    File.read(template_path)
  end

  def template_path
    File.expand_path('../templates/patch.md.erb', __dir__)
  end
end
