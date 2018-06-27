require_relative '../ref'
require_relative '../project_changeset'
require_relative '../issuable_omitter_by_labels'
require_relative '../issue'

module Qa
  module Services
    class QaIssueService
      attr_reader :version, :from, :to, :issue_project, :projects

      def initialize(version:, from:, to:, issue_project:, projects:)
        @version = version
        @from = Ref.new(from)
        @to = Ref.new(to)
        @issue_project = issue_project
        @projects = projects
      end

      def execute
        issue.create

        issue
      end

      def issue
        @issue ||= Qa::Issue.new(version: version,
                                 project: issue_project,
                                 merge_requests: merge_requests)
      end

      def changesets
        @changesets ||= projects.map do |project|
          ProjectChangeset.new(project, from.for_project(project), to.for_project(project))
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

      def sort_merge_requests
        raise NotImplementedError
      end
    end
  end
end
