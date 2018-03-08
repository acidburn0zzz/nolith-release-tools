require 'gitlab'

# Public: Gitlab API operations with Dev instance
class GitlabDevClient
  DEFAULT_GITLAB_DEV_API_ENDPOINT = 'https://dev.gitlab.org/api/v4'.freeze

  # Hard-code IDs following the 'namespace/repo' pattern
  OMNIBUS_GITLAB = 'gitlab/omnibus-gitlab'.freeze
  REPO_VARIABLE = 'PACKAGECLOUD_REPO'.freeze

  class << self
    # Public: Creates a CI variable and store the repository name
    #
    # name - The String name of the repository
    #
    # Returns a Gitlab::ObjectifiedHash
    def create_repo_variable(name)
      client.create_variable(OMNIBUS_GITLAB, REPO_VARIABLE, name)
    end

    # Public: Remove CI variable with stored repository name
    #
    # Returns a Boolean
    def remove_repo_variable
      client.remove_variable(OMNIBUS_GITLAB, REPO_VARIABLE)
      true
    rescue Gitlab::Error::NotFound
      false
    end

    # Public: Fetch CI variable with stored repository name
    #
    # Returns either a String or False
    def fetch_repo_variable
      client.variable(OMNIBUS_GITLAB, REPO_VARIABLE).value
    rescue Gitlab::Error::NotFound
      false
    end

    private

    # Private: A client connected to GitLab DEV instance
    #
    # Returns a Gitlab::Client instance
    def client
      @client ||= Gitlab.client(
        endpoint: DEFAULT_GITLAB_DEV_API_ENDPOINT,
        private_token: ENV['GITLAB_DEV_API_PRIVATE_TOKEN']
      )
    end
  end
end
