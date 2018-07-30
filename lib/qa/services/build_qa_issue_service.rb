require_relative '../../shared_status'
require_relative '../ref'
require_relative '../project_changeset'
require_relative '../issuable_omitter_by_labels'
require_relative '../issue'
require_relative '../security_issue'

module Qa
  module Services
    class BuildQaIssueService
      attr_reader :version, :from, :to, :issue_project, :projects

      def initialize(version:, from:, to:, issue_project:, projects:)
        @version = version
        @from = Ref.new(from)
        @to = Ref.new(to)
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
          merge_requests: merge_requests)
      end

      def changesets
        @changesets ||= projects.map do |project|
          ProjectChangeset.new(
            project: project,
            from: from.for_project(project),
            to: to.for_project(project),
            default_client: default_client)
        end
      end

      def merge_requests
        merge_requests = changesets
          .map(&:merge_requests)
          .flatten
          .uniq(&:id)

        IssuableOmitterByLabels.new(merge_requests, Qa::UNPERMITTED_LABELS)
          .execute
      end

      private

      def issue_class
        SharedStatus.security_release? ? Qa::SecurityIssue : Qa::Issue
      end

      def default_client
        SharedStatus.security_release? ? GitlabDevClient : GitlabClient
      end
    end
  end
end
