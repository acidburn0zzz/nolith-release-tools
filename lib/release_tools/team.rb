# frozen_string_literal: true

module ReleaseTools
  class Team
    USERS_API_URL = 'https://gitlab.com/api/v4/projects/278964/users.json'

    CORE_TEAM = %w[
      razer6
      haynes
      newton
      blackst0ne
      tnir
      jacopo-beschi
    ].freeze

    def initialize(members: nil, included_core_members: [])
      @members = members
      @core_team = CORE_TEAM - included_core_members
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
          response = HTTP.get("#{USERS_API_URL}?per_page=100&page=#{i}")

          users = response.parse

          break if users.empty?

          users.each do |user|
            next if @core_team.include?(user['username'])

            members << TeamMember.new(name: user['name'], username: user['username'])
          end

          break if response.headers['x-next-page'].empty?
        end

        members
      end
    end

    def normalize_name(name)
      name.gsub(/\(.*?\)/, '').squeeze(' ').strip.downcase
    end
  end
end
