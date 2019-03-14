# frozen_string_literal: true

module ReleaseTools
  module Project
    class CNGImage < BaseProject
      REMOTES = {
        dev: 'git@dev.gitlab.org:balasankarc/images.git',
        gitlab: 'git@gitlab.com:balasankarc/CNG.git',
      }.freeze
    end
  end
end
