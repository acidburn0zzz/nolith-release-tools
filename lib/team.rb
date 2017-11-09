require 'team_member'

class Team
  TEAM_DATA_URL = 'https://gitlab.com/gitlab-com/www-gitlab-com/raw/master/data/team.yml'.freeze
  CORE_TEAM = [
    TeamMember.new(name: 'blackst0ne', username: 'blackst0ne')
  ].freeze

  def initialize(members: nil)
    @members = members
  end

  # Return an array of TeamMember
  def to_a
    members
  end

  def find_by_name(name)
    members.find { |member| member.name == name }
  end

  private

  def members
    @members ||= begin
      response = HTTParty.get(TEAM_DATA_URL)

      members =
        YAML.safe_load(response.body).map do |member|
          TeamMember.new(name: member['name'], username: member['gitlab'])
        end

      members + CORE_TEAM
    end
  end
end
