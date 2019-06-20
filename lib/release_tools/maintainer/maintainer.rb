# frozen_string_literal: true

module ReleaseTools
  class Maintainer
    class << self
      def project_maintainer?(username, project)
        member = team_member(username, project.path)

        member &&
          member.access_level >= ReleaseTools::ReleaseManagers::Client::MASTER_ACCESS
      end

      private

      def team_member(username, project_path)
        client.team_members(project_path, query: username).find do |user|
          user.username.casecmp?(username)
        end
      end

      def client
        @client ||= Gitlab.client(
          endpoint: ::ReleaseTools::ReleaseManagers::Client::GITLAB_API_ENDPOINT,
          private_token: ENV['GITLAB_API_PRIVATE_TOKEN']
        )
      end
    end
  end
end
