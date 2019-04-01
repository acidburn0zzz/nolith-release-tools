# frozen_string_literal: true

module ReleaseTools
  module Project
    class HelmGitlab < BaseProject
      REMOTES = {
        gitlab: 'git@gitlab.com:charts/gitlab.git'
      }.freeze
    end
  end
end
