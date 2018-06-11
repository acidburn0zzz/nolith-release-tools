require_relative '../ref'
require_relative '../project_changeset'
require_relative '../issuable_deduplicator'
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
        if issue.remote_issuable
          issue.update
          issue.add_comment
        else
          issue.create
        end

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
        all_mrs = changesets.map(&:merge_requests).flatten
        uniq_mrs = IssuableDeduplicator.new(all_mrs).execute
        IssuableOmitterByLabels.new(uniq_mrs, Qa::UNPERMITTED_LABELS).execute
      end

      private

      def sort_merge_requests
        raise NotImplementedError
      end
    end
  end
end
