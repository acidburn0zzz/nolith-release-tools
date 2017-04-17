require_relative 'version'

class OmnibusGitLabVersion < Version
  VERSION_REGEX = %r{
    \A(?<major>\d+)
    \.(?<minor>\d+)
    (\.(?<patch>\d+))?
    (\+)?
    (?<rc>rc(?<rc_number>\d*))?
    (\.)?
    (?<ed>ce|ee)?
    (\.\d+)?\z
  }x

  def ee?
    edition == 'ee'
  end

  def edition
    @edition ||= extract_from_version(:ed, fallback: 'ce')
  end

  def tag
    str = "#{to_patch}+"
    str << "rc#{rc}." if rc?
    str << (ee? ? 'ee' : 'ce')
    str << '.0'
  end
end
