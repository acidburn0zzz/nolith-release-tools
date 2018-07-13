require_relative 'version'

class HelmChartVersion < Version
  VERSION_REGEX = %r{
    \A(?<major>\d+)
    \.(?<minor>\d+)
    (\.(?<patch>\d+))?\z
  }x
end
