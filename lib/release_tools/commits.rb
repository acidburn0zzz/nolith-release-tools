# frozen_string_literal: true

module ReleaseTools
  class Commits
    attr_reader :project
    MAX_COMMITS_TO_CHECK = 100

    def initialize(project, client = ReleaseTools::GitlabClient)
      @project = project
      @client = client
    end

    def latest_successful
      filter_for_green_builds
    end

    private

    def commit_list
      @commit_list ||= @client.commits(
        @project.path,
        per_page: 1,
        ref_name: 'master'
      )
    end

    def filter_for_green_builds
      commit_counter = 0
      commit_list.auto_paginate do |commit|
        commit_counter += 1
        if commit_counter > MAX_COMMITS_TO_CHECK
          abort("Examined #{MAX_COMMITS_TO_CHECK} commits, " \
                "but could not find a passing " \
                "build for #{@project.path}, aborting")
        end
        commit = @client.commit(@project, ref: commit.id)
        return commit if commit.status == "success"
      end
    end
  end
end
