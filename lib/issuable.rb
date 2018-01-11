require 'erb'
require 'ostruct'

class Issuable < OpenStruct
  def initialize(*args)
    super
    yield self if block_given?
  end

  def description
    ERB.new(template).result(binding)
  end

  def project
    self[:project] || default_project
  end

  def iid
    remote_issuable&.iid
  end

  def created_at
    self[:created_at] = Time.parse(self[:created_at]) if self[:created_at]&.is_a?(String)

    super
  end

  def exists?
    !remote_issuable.nil?
  end

  def create
    raise NotImplementedError
  end

  def remote_issuable
    raise NotImplementedError
  end

  def url
    remote_issuable.web_url
  end

  private

  def default_project
    Project::GitlabCe
  end

  def template
    File.read(template_path)
  end
end
