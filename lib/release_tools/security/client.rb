# frozen_string_literal: true

module ReleaseTools
  module Security
    # A GitLab API client to use when validating security merge requests.
    class Client
      # The API endpoint to use for validating merge requests.
      #
      # This uses dev.gitlab.org opposed to gitlab.com, as security merge
      # requests are submitted on dev.gitlab.org.
      API_ENDPOINT = 'https://dev.gitlab.org/api/v4'

      # The username of the release tools bot that is responsible for verifying
      # security merge requests.
      RELEASE_TOOLS_BOT_USERNAME = 'gitlab-release-tools-bot'

      attr_reader :gitlab_client

      def initialize
        @gitlab_client = ::Gitlab.client(
          endpoint: API_ENDPOINT,
          private_token: ENV.fetch('RELEASE_BOT_DEV_TOKEN')
        )
      end

      # @param [String] project The full project path, such as
      # `gitlab-org/gitlab-ce`.
      def open_security_merge_requests(project)
        # We use a `per_page` of 100 so we get as many merge requests as
        # posibble in a single request.
        gitlab_client.merge_requests(
          project,
          per_page: 100,
          labels: 'security',
          state: 'opened',
          assignee_id: release_tools_bot.id
        )
        .auto_paginate
      end

      # @return [Gitlab::ObjectifiedHash]
      def release_tools_bot
        @release_tools_bot ||= gitlab_client
          .users(username: RELEASE_TOOLS_BOT_USERNAME)
          .first
      end

      # @param [Integer|String] project_id
      # @param [Integer] merge_request_iid
      # @return [Gitlab::ObjectifiedHash]
      def latest_merge_request_pipeline(project_id, merge_request_iid)
        # Since this API does not allow sorting _and_ returns pipelines in an
        # inconsistent order, we must sort this list manually.
        gitlab_client
          .merge_request_pipelines(project_id, merge_request_iid)
          .auto_paginate
          .max_by(&:id)
      end

      def method_missing(name, *args)
        if gitlab_client.respond_to?(name)
          gitlab_client.public_send(name, *args)
        else
          super
        end
      end

      def respond_to_missing?(name, include_private = false)
        gitlab_client.respond_to?(name, include_private)
      end
    end
  end
end
