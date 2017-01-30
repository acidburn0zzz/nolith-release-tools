require 'gitlab'

class GitlabDevClient
  class InvalidProjectException < ArgumentError
  end
  # Hard-code IDs following the 'namespace%2Frepo' pattern
  OMNIBUS_GITLAB = 'gitlab%2Fomnibus-gitlab'.freeze
  REPO_VARIABLE = 'PACKAGECLOUD_REPO'.freeze

  class << self
    # @param [String] repository name
    def create_repo_variable(name)
      client.create_variable(OMNIBUS_GITLAB, REPO_VARIABLE, name)
    end

    def remove_repo_variable
      client.remove_variable(OMNIBUS_GITLAB, REPO_VARIABLE)
    end

    def fetch_repo_variable
      client.variable(OMNIBUS_GITLAB, REPO_VARIABLE)
    rescue Gitlab::Error::NotFound
      false
    end

    private

    def client
      @client ||= Gitlab.client(endpoint: ENV['GITLAB_DEV_API_ENDPOINT'], private_token: ENV['GITLAB_DEV_API_PRIVATE_TOKEN'])
    end
  end
end
