require_relative 'version'
require_relative 'helm_chart_version'

class HelmGitlabVersion < Version
  VERSION_REGEX = %r{
    \A(?<major>\d+)
    \.(?<minor>\d+)
    (\.(?<patch>\d+))?
    (-(?<rc>rc(?<rc_number>\d*)))?\z
  }x

  def diff(other)
    if major != other.major
      :major
    elsif minor != other.minor
      :minor
    elsif patch != other.patch
      :patch
    elsif rc != other.rc
      :rc
    end
  end
end
