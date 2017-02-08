require 'packagecloud'
require_relative 'package_version'

# Public: Packagecloud Client facade with customizations to access our
# own instance
class PackagecloudClient
  attr_accessor :username, :token

  GITLAB_CE_PUBLIC_REPO = 'gitlab-ce'.freeze
  GITLAB_EE_PUBLIC_REPO = 'gitlab-ee'.freeze

  # username - The username as String
  # token    - The token as String
  def initialize(username = nil, token = nil)
    @username = username || ENV['PACKAGECLOUD_USER']
    @token = token || ENV['PACKAGECLOUD_TOKEN']
  end

  # Public: Packagecloud credentials object
  #
  # Returns a Packagecloud::Credentials object
  def credentials
    @credentials ||= Packagecloud::Credentials.new(username, token)
  end

  # Public: Connection object pointing to our own instance
  #
  # Returns a Packagecloud::Connection object
  def connection
    @connection ||= Packagecloud::Connection.new('https', 'packages.gitlab.com')
  end

  # Public: Packagecloud API client with our credentials and connection to our
  # instance
  #
  # @return [Packagecloud::Client]
  def client
    @client ||= Packagecloud::Client.new(credentials, 'gitlab-release-tool', connection)
  end

  # Public: Creates a secret repository
  #
  # secret_repo - The repository name as String
  #
  # Returns a Boolean
  def create_secret_repository(secret_repo)
    # Make sure the security release repository exists or create otherwhise
    if client.repository(secret_repo).succeeded
      false
    else
      result = client.create_repository(secret_repo, true)
      if result.succeeded
        true
      else
        $stdout.puts "Cannot create security release repository: #{result.response}"
        false
      end
    end
  end

  # Public: Promote packages from secret repository to public ones
  #
  # secret_repo - The repository name as String
  #
  # Returns a Boolean
  def promote_packages(secret_repo)
    packages = client.list_packages(secret_repo)
    if packages.succeeded
      packages.response.count
      packages.response.map do |p|
        distro, version = p['distro_version'].split('/')
        client.promote_package(secret_repo, distro, version, p['filename'], public_repo_for_package(p['filename']))
      end
      true
    else
      $stdout.puts 'Cannot find the security release repository'
      false
    end
  end

  # Public: Find in which public repository should the package be
  #
  # filename - The filename as String
  #
  # Returns the public repository name as String
  def public_repo_for_package(filename)
    pkg = ::PackageVersion.new(filename)
    if pkg.ce?
      GITLAB_CE_PUBLIC_REPO
    else
      GITLAB_EE_PUBLIC_REPO
    end
  end
end
