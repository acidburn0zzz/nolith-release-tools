require 'gitlab'

class GitlabDevClient
  # Hard-code IDs following the 'namespace%2Frepo' pattern
  CE_PROJECT_DEV_ID = 'gitlab%2Fgitlabhq'.freeze
  EE_PROJECT_DEV_ID = 'gitlab%2Fgitlab-ee'.freeze

  class << self
    def ce_create_variable(value)
      client.create_variable(CE_PROJECT_DEV_ID, 'PACKAGECLOUD_REPO', value)
    end

    def ce_remove_variable(value)
      client.remove_variable(CE_PROJECT_DEV_ID, value)
    end

    def ee_create_variable(value)
      client.create_variable(EE_PROJECT_DEV_ID, 'PACKAGECLOUD_REPO', value)
    end

    def ee_remove_variable(value)
      client.remove_variable(EE_PROJECT_DEV_ID, value)
    end

    private

    def client
      @client ||= Gitlab.client(endpoint: ENV['GITLAB_DEV_API_ENDPOINT'], private_token: ENV['GITLAB_DEV_API_PRIVATE_TOKEN'])
    end
  end
end
