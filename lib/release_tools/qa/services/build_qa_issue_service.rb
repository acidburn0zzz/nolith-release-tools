# frozen_string_literal: true

module ReleaseTools
  module Qa
    module Services
      class BuildQaIssueService
        attr_reader :version, :from, :to, :issue_project, :projects

        def initialize(version:, from:, to:, issue_project:, projects:)
          @version = version
          @from = ReleaseTools::Qa::Ref.new(from)
          @to = ReleaseTools::Qa::Ref.new(to)
          @issue_project = issue_project
          @projects = projects
        end

        def execute
          issue
        end

        def issue
          @issue ||= issue_class.new(
            version: version,
            project: issue_project,
            merge_requests: merge_requests
          )
        end

        def changesets
          @changesets ||= projects.map do |project|
            ReleaseTools::Qa::ProjectChangeset.new(
              project: project,
              from: from.for_project(project),
              to: to.for_project(project),
              default_client: default_client
            )
          end
        end

        def merge_requests
          merge_requests = changesets
            .map(&:merge_requests)
            .flatten
            .uniq(&:id)

          ReleaseTools::Qa::IssuableOmitterByLabels
            .new(merge_requests)
            .execute
        end

        private

        def issue_class
          if ReleaseTools::SharedStatus.security_release?
            ReleaseTools::Qa::SecurityIssue
          else
            ReleaseTools::Qa::Issue
          end
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
end
