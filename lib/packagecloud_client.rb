require 'packagecloud'

class PackagecloudClient
  attr_accessor :user, :token

  def initialize(user, token)
    @user = user
    @token = token
  end

  def credentials
    @credentials ||= Packagecloud::Credentials.new(user, token)
  end

  def connection
    @connection ||= Packagecloud::Connection.new('https', 'packages.gitlab.com')
  end

  def client
    @client ||= Packagecloud::Client.new(credentials, "packagecloud-ruby #{Packagecloud::VERSION}", connection)
  end

  def create_secret_repository(secret_repo)
    # Make sure the security release repository exists or create otherwhise
    unless client.repository(secret_repo).succeeded
      result = client.create_repository(secret_repo, true)
      unless result.succeeded
        $stdout.puts "Cannot create security release repository"
        false
      end
    end
  end

  def promote_packages(secret_repo, public_repo)
    packages = client.list_packages(secret_repo)
    if packages.succeeded
      packages.response.count
      packages.response.map do |p|
        distro, version = p['distro_version'].split('/')
        client.promote_package(secret_repo, distro, version, p['filename'], public_repo)
      end
    else
      $stdout.puts "Cannot find the security release repository"
    end
  end
end
