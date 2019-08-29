# frozen_string_literal: true

module ReleaseTools
  module Qa
    class MergeRequests
      def initialize(projects:, from:, to:)
        @projects = projects
        @from = from
        @to = to
      end

      def to_a
        ReleaseTools::Qa::IssuableOmitterByLabels.new(merge_requests).execute
      end

      def merge_requests
        changesets = @projects.map do |project|
          ReleaseTools::Qa::ProjectChangeset.new(
            project: project,
            from: @from.for_project(project),
            to: @to.for_project(project),
            default_client: default_client
          )
        end

        changesets.flat_map(&:merge_requests).uniq(&:id)
      end

      def default_client
        if ReleaseTools::SharedStatus.security_release?
          ReleaseTools::GitlabDevClient
        else
          ReleaseTools::GitlabClient
        end
      end
    end
  end
end
