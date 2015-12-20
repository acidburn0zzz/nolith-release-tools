require 'erb'

require_relative 'client'

class BaseIssue
  def description
    ERB.new(template).result(binding)
  end

  def create
    Client.create_issue(self)
  end

  def exists?
    !remote_issue.nil?
  end

  def remote_issue
    Client.find_open_issue(self)
  end

  def url
    if exists?
      Client.issue_url(remote_issue)
    else
      ''
    end
  end

  protected

  def template
    File.read(template_path)
  end
end
