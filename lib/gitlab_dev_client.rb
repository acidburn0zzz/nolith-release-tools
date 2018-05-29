require 'gitlab_client'

class GitlabDevClient < GitlabClient
  DEV_API_ENDPOINT = 'https://dev.gitlab.org/api/v4'.freeze

  def self.client
    @client ||= Gitlab.client(
      endpoint: DEV_API_ENDPOINT,
      private_token: ENV['DEV_API_PRIVATE_TOKEN']
    )
  end
end
