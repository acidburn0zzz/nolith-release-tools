require 'forwardable'

module ReleaseManagers
  # Represents all defined Release Managers
  class Definitions
    extend Forwardable
    include Enumerable

    attr_accessor :config_file
    attr_reader :all

    def_delegator :@all, :each

    class << self
      extend Forwardable

      def_delegator :new, :allowed?
      def_delegator :new, :sync!
    end

    def initialize(config_file = nil)
      @config_file = config_file ||
        File.expand_path('../../config/release_managers.yml', __dir__)

      reload!
    end

    def allowed?(username)
      any? { |user| user.production == username }
    end

    def reload!
      begin
        content = YAML.load_file(config_file)
        raise ArgumentError, "#{config_file} contains no data" if content.blank?
      rescue Errno::ENOENT
        raise ArgumentError, "#{config_file} does not exist!"
      end

      @all = content.map { |name, hash| User.new(name, hash) }
    end

    def sync!
      dev_client.sync_membership(all.collect(&:dev))
      production_client.sync_membership(all.collect(&:production))
    end

    private

    def dev_client
      @dev_client ||= ReleaseManagers::Client.new(:dev)
    end

    def production_client
      @production_client ||= ReleaseManagers::Client.new(:production)
    end

    # Represents a single entry from the configuration file
    class User
      attr_reader :name
      attr_reader :dev, :github, :production

      def initialize(name, hash)
        if hash['gitlab.com'].nil?
          raise ArgumentError, "No `gitlab.com` value for #{name}"
        end

        @name = name

        @production = hash['gitlab.com']
        @dev        = hash['gitlab.org'] || production
        @github     = hash['github.com'] || production
      end
    end
  end
end
