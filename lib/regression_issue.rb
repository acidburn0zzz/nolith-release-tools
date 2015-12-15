require 'erb'

require_relative 'client'
require_relative 'version'

class RegressionIssue
  attr_reader :version

  def initialize(version)
    @version = version
  end

  def title
    "#{version.to_minor} Regressions"
  end

  def description
    ERB.new(template).result(binding)
  end

  def labels
    'regression'
  end

  def create
    Client.create_issue(self)
  end

  private

  def template
    File.read(template_path)
  end

  def template_path
    File.expand_path('../templates/regression.md.erb', __dir__)
  end
end
