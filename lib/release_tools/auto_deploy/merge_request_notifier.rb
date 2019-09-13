# frozen_string_literal: true

module ReleaseTools
  module AutoDeploy
    class MergeRequestNotifier
      include ::SemanticLogger::Loggable

      DEFAULT_ENVIRONMENT = 'gstg'

      ENVIRONMENT_LABELS = {
        'gstg' => 'workflow::staging',
        'gprd-cny' => 'workflow::canary',
        'gprd' => 'workflow::production'
      }.freeze

      NOTIFICATION = <<~COMMENT.strip
        This merge request has been deployed to the GitLab.com environment
        `%<environment>s` in GitLab auto-deploy version `%<version>s`.

        A list of all the deployed commits can be found [here][commits].

        <hr>

        :robot: If this message is incorrect, please create an issue in the
        [Release Tools][release-tools] project.

        [release-tools]: https://gitlab.com/gitlab-org/release-tools/
        [commits]: https://gitlab.com/gitlab-org/gitlab/compare/%<from_ref>s...%<to_ref>s

        /label ~"%<environment_label>s"
      COMMENT

      GITLAB_COM_HOSTS = Set.new(%w[gitlab.com www.gitlab.com]).freeze

      def initialize(
        from:,
        to:,
        version:,
        environment: ENV['RELEASE_ENVIRONMENT'] || DEFAULT_ENVIRONMENT
      )
        @from = Qa::Ref.new(from)
        @to = Qa::Ref.new(to)
        @version = version
        @environment = environment
      end

      def notify_all
        Parallel.each(merge_requests, in_threads: Etc.nprocessors) do |mr|
          if notify?(mr)
            notify(mr)
          else
            logger.info(
              "Skipping as it is not a GitLab.com merge request",
              merge_request: mr.web_url
            )
          end
        end
      end

      def notify(merge_request)
        label = ENVIRONMENT_LABELS.fetch(@environment)

        if merge_request.labels.include?(label)
          logger.info(
            "Merge request has already been notified",
            merge_request: merge_request.web_url
          )

          return
        end

        logger.info(
          "Notifying about the deploy to #{@environment}",
          merge_request: merge_request.web_url
        )

        GitlabClient.create_merge_request_comment(
          merge_request.project_id,
          merge_request.iid,
          format(
            NOTIFICATION,
            environment: @environment,
            version: @version,
            environment_label: label,
            from_ref: @from.ref,
            to_ref: @to.ref
          )
        )
      end

      def notify?(merge_request)
        host = URI.parse(merge_request.web_url).host

        GITLAB_COM_HOSTS.include?(host)
      end

      def merge_requests
        Qa::MergeRequests.new(projects: Qa::PROJECTS, from: @from, to: @to).to_a
      end
    end
  end
end
