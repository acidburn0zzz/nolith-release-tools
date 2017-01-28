require 'gitlab'

class GitlabDevClient
  class InvalidProjectException < ArgumentError
  end
  # Hard-code IDs following the 'namespace%2Frepo' pattern
  CE_PROJECT_DEV_ID = 'gitlab%2Fgitlabhq'.freeze
  EE_PROJECT_DEV_ID = 'gitlab%2Fgitlab-ee'.freeze
  REPO_VARIABLE = 'PACKAGECLOUD_REPO'.freeze

  class << self
    def create_variable(project_type, value)
      client.create_variable(project(project_type), REPO_VARIABLE, value)
    end

    def remove_variable(project_type)
      client.remove_variable(project(project_type), REPO_VARIABLE)
    end

    def find_variable(project_type)
      client.find_variable(project(project_type), REPO_VARIABLE)
    end

    private

    def client
      @client ||= Gitlab.client(endpoint: ENV['GITLAB_DEV_API_ENDPOINT'], private_token: ENV['GITLAB_DEV_API_PRIVATE_TOKEN'])
    end

    def project(project_type)
      case project_type
      when :ce
        CE_PROJECT_DEV_ID
      when :ee
        EE_PROJECT_DEV_ID
      else
        raise ArgumentError, 'Invalid project type'
      end
    end
  end
end
