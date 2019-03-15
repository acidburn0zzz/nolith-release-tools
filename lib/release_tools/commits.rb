# frozen_string_literal: true

module ReleaseTools
  class Commits
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def latest_successful
      filter_for_green_builds
    end

    private

    def commit_list
      @commit_list ||= ReleaseTools::GitlabDevClient.commits(
        @project.dev_path,
        {
          per_page: 1,
          ref_name: 'master'
        })
    end

    def filter_for_green_builds
      commit_list.auto_paginate do |commit|
        commit = ReleaseTools::GitlabDevClient.commit(@project, ref: commit.id)
        return commit if commit.status == "success"
      end
    end
  end
end
