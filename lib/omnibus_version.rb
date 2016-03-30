require_relative 'version'

class OmnibusVersion < Version
  def tag
    str = "#{to_patch}+"
    str << "#{rc}." if rc?
    str << (ee? ? 'ee' : 'ce')
    str << '.0'
  end
end
