require 'erb'

require_relative 'gitlab_client'

class BaseIssue
  def description
    ERB.new(template).result(binding)
  end

  def create
    GitlabClient.create_issue(self)
  end

  def exists?
    !remote_issue.nil?
  end

  def remote_issue
    GitlabClient.find_issue(self)
  end

  def url
    if exists?
      GitlabClient.issue_url(remote_issue)
    else
      ''
    end
  end

  protected

  def template
    File.read(template_path)
  end
end
