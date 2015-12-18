require 'erb'

require_relative 'client'

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

  def exists?
    !remote_issue.nil?
  end

  def remote_issue
    @remote_issue ||= Client.find_open_issue(self)
  end

  def url
    if exists?
      Client.issue_url(remote_issue)
    else
      ''
    end
  end

  private

  def template
    File.read(template_path)
  end

  def template_path
    File.expand_path('../templates/regression.md.erb', __dir__)
  end
end
