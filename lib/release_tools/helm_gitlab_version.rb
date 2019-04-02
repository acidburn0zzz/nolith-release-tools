# frozen_string_literal: true

module ReleaseTools
  class HelmGitlabVersion < Version
    VERSION_REGEX = %r{
      \A(?<major>\d+)
      \.(?<minor>\d+)
      (\.(?<patch>\d+))?
      (-(?<rc>rc(?<rc_number>\d*)))?\z
    }x.freeze

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
end
