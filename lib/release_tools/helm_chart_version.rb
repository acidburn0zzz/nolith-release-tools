# frozen_string_literal: true

module ReleaseTools
  class HelmChartVersion < Version
    VERSION_REGEX = %r{
      \A(?<major>\d+)
      \.(?<minor>\d+)
      (\.(?<patch>\d+))?\z
    }x.freeze
  end
end
