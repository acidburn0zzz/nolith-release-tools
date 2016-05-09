require_relative 'version'

class OmnibusGitLabVersion < Version
  def tag
    str = "#{to_patch}+"
    str << "#{rc}." if rc?
    str << (ee? ? 'ee' : 'ce')
    str << '.0'
  end
end
