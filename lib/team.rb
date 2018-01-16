require 'json'
require_relative 'team_member'

class Team
  USERS_API_URL = 'https://gitlab.com/api/v4/projects/278964/users.json'.freeze

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
    normalized_name = normalize_name(name)

    members.find do |member|
      normalize_name(member.name) == normalized_name
    end
  end

  private

  def members
    @members ||= begin
      members = []

      100.times do |i|
        response = HTTParty.get("#{USERS_API_URL}?per_page=100&page=#{i}")

        users = JSON.parse(response.body)

        break if users.empty?

        users.each do |user|
          members << TeamMember.new(name: user['name'], username: user['username'])
        end

        break if response.headers['x-next-page'].empty?
      end

      members + CORE_TEAM
    end
  end

  def normalize_name(name)
    name.gsub(/\(.*?\)/, '').squeeze(' ').strip.downcase
  end
end
