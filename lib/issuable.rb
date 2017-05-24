require 'erb'

class Issuable
  def description
    ERB.new(template).result(binding)
  end

  def create
    raise NotImplementedError
  end

  def remote_issuable
    raise NotImplementedError
  end

  def exists?
    !remote_issuable.nil?
  end

  def url
    if exists?
      _url
    else
      ''
    end
  end

  private

  def template
    File.read(template_path)
  end

  def _url
    raise NotImplementedError
  end
end
