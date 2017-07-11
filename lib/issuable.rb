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
    self[:project] || Project::GitlabCe
  end

  def iid
    remote_issuable&.iid
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
    raise NotImplementedError
  end

  private

  def template
    File.read(template_path)
  end
end
