# frozen_string_literal: true

module ReleaseTools
  class GitlabDevClient < GitlabClient
    DEV_API_ENDPOINT = 'https://dev.gitlab.org/api/v4'

    def self.project_path(project)
      project.dev_path
    end

    def self.client
      @client ||= Gitlab.client(
        endpoint: DEV_API_ENDPOINT,
        private_token: ENV['DEV_API_PRIVATE_TOKEN']
      )
    end
  end
end
