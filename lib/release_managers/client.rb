module ReleaseManagers
  class Client
    SyncError = Class.new(StandardError)
    UserNotFoundError = Class.new(SyncError)
    UnauthorizedError = Class.new(SyncError)

    GITLAB_API_ENDPOINT = 'https://gitlab.com/api/v4'.freeze
    DEV_API_ENDPOINT = 'https://dev.gitlab.org/api/v4'.freeze
    OPS_API_ENDPOINT = 'https://ops.gitlab.net/api/v4'.freeze

    MASTER_ACCESS = 40

    attr_reader :sync_errors, :target

    # Initialize a GitLab API client specific to Release Manager tasks
    #
    # target - Target :production, :dev or :ops environment (default: :production)
    def initialize(target = :production)
      @sync_errors = []
      @target = target

      case target
      when :dev
        @group = 'gitlab/release/managers'.freeze
        @client = Gitlab.client(
          endpoint: DEV_API_ENDPOINT,
          private_token: ENV['DEV_API_PRIVATE_TOKEN']
        )
      when :ops
        @group = 'release-managers'
        @client = Gitlab.client(
          endpoint: OPS_API_ENDPOINT,
          private_token: ENV['OPS_API_PRIVATE_TOKEN']
        )
      else
        @target = :production
        @group = 'gitlab-org/release/managers'.freeze
        @client = Gitlab.client(
          endpoint: GITLAB_API_ENDPOINT,
          private_token: ENV['GITLAB_API_PRIVATE_TOKEN']
        )
      end
    end

    def members
      client.group_members(group)
    end

    def sync_membership(usernames)
      $stdout.puts "--> Syncing #{target}"

      usernames.map!(&:downcase)
      existing = members.collect(&:username).map(&:downcase)

      to_add = usernames - existing
      to_remove = existing - usernames

      to_add.each do |username|
        track_sync_errors { add_member(username) }
      end
      to_remove.each do |username|
        track_sync_errors { remove_member(username) }
      end
    rescue Gitlab::Error::Unauthorized
      sync_errors << UnauthorizedError.new("Unauthorized")
    rescue Gitlab::Error::Forbidden
      sync_errors << UnauthorizedError.new('Insufficient permissions')
    end

    def get_user(username)
      user = client
        .user_search(username)
        .auto_paginate
        .detect { |result| result.username.casecmp?(username) }

      user || raise(UserNotFoundError, "#{username} not found")
    end

    private

    attr_reader :client, :group

    def add_member(username)
      user = get_user(username)

      $stdout.puts "    Adding #{user.username} to #{group}"
      client.add_group_member(group, user.id, MASTER_ACCESS)
    rescue Gitlab::Error::Conflict => ex
      raise SyncError.new(ex) unless ex.message =~ /Member already exists/
    rescue Gitlab::Error::BadRequest => ex
      # Ignore when a new member has greater permissions via group inheritance
      raise SyncError.new(ex) unless ex.message =~ /should be higher/
    end

    def remove_member(username)
      user = get_user(username)

      $stdout.puts "    Removing #{username} from #{group}"
      client.remove_group_member(group, user.id)
    end

    def track_sync_errors
      yield
    rescue SyncError => e
      sync_errors << e
    end
  end
end
