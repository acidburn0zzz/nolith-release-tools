# frozen_string_literal: true

module ReleaseTools
  class GitlabOpsClient < GitlabClient
    OPS_API_ENDPOINT = 'https://ops.gitlab.net/api/v4'

    def self.project_path(project)
      project.path
    end

    def self.client
      @client ||= Gitlab.client(
        endpoint: OPS_API_ENDPOINT,
        private_token: ENV['OPS_API_PRIVATE_TOKEN']
      )
    end
  end
end
