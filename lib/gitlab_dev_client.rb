require 'gitlab'

# Gitlab API operations with Dev instance
class GitlabDevClient
  class InvalidProjectException < ArgumentError
  end

  # Hard-code IDs following the 'namespace%2Frepo' pattern
  OMNIBUS_GITLAB = 'gitlab%2Fomnibus-gitlab'.freeze
  REPO_VARIABLE = 'PACKAGECLOUD_REPO'.freeze

  class << self
    # Creates a CI variable and store the repository name
    #
    # @param [String] name of the repository
    # @return [Gitlab::ObjectifiedHash]
    def create_repo_variable(name)
      client.create_variable(OMNIBUS_GITLAB, REPO_VARIABLE, name)
    end

    # Remove CI variable with stored repository name
    #
    # @return [Boolean]
    def remove_repo_variable
      client.remove_variable(OMNIBUS_GITLAB, REPO_VARIABLE)
      true
    rescue Gitlab::Error::NotFound
      false
    end

    # Fetch CI variable with stored repository name
    #
    # @return [String|false]
    def fetch_repo_variable
      client.variable(OMNIBUS_GITLAB, REPO_VARIABLE).value
    rescue Gitlab::Error::NotFound
      false
    end

    private

    def client
      @client ||= Gitlab.client(endpoint: ENV['GITLAB_DEV_API_ENDPOINT'], private_token: ENV['GITLAB_DEV_API_PRIVATE_TOKEN'])
    end
  end
end
