# frozen_string_literal: true

module ReleaseTools
  module Project
    class CNGImage < BaseProject
      REMOTES = {
        dev: 'git@dev.gitlab.org:gitlab/charts/components/images.git',
        gitlab: 'git@gitlab.com:gitlab-org/build/CNG.git'
      }.freeze
    end
  end
end
