# frozen_string_literal: true

module ReleaseTools
  module Project
    class ReleaseTools < BaseProject
      REMOTES = {
        canonical: 'git@gitlab.com:gitlab-org/release-tools.git'
      }.freeze
    end
  end
end
