module ReleaseManagers
  class Client
    GITLAB_API_ENDPOINT = 'https://gitlab.com/api/v4'.freeze
    DEV_API_ENDPOINT = 'https://dev.gitlab.org/api/v4'.freeze

    MASTER_ACCESS = 40

    # Initialize a GitLab API client specific to Release Manager tasks
    #
    # target - Target :production or :dev environment (default: :production)
    def initialize(target = :production)
      @target = target

      case target
      when :dev
        @group = 'gitlab/release/managers'.freeze
        @client = Gitlab.client(
          endpoint: DEV_API_ENDPOINT,
          private_token: ENV['DEV_API_PRIVATE_TOKEN']
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

      existing = members.collect(&:username)

      to_add = usernames - existing
      to_remove = existing - usernames

      to_add.each { |username| add_member(username) }
      to_remove.each { |username| remove_member(username) }
    rescue Gitlab::Error::Unauthorized
      $stderr.puts "Unauthorized on #{client.endpoint}"
      exit 1
    rescue Gitlab::Error::Forbidden
      $stderr.puts "Insufficient permissions on #{client.endpoint}"
      exit 1
    end

    def get_user(username)
      user = client
        .user_search(username)
        .detect { |result| result.username.casecmp?(username) }

      user || raise("#{username} not found on #{client.endpoint}")
    end

    private

    attr_reader :client, :group, :target

    def add_member(username)
      user = get_user(username)

      begin
        $stdout.puts "    Adding #{username} to #{group}"
        client.add_group_member(group, user.id, MASTER_ACCESS)
      rescue Gitlab::Error::Conflict => ex
        raise unless ex.message =~ /Member already exists/
      end
    end

    def remove_member(username)
      user = get_user(username)

      $stdout.puts "    Removing #{username} from #{group}"
      client.remove_group_member(group, user.id)
    end
  end
end
