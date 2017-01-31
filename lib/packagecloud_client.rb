require 'packagecloud'

class PackagecloudClient
  attr_accessor :user, :token

  GITLAB_CE_PUBLIC_REPO = 'gitlab-ce'.freeze
  GITLAB_EE_PUBLIC_REPO = 'gitlab-ee'.freeze

  def initialize(user = nil, token = nil)
    @user = user || ENV['PACKAGECLOUD_USER']
    @token = token || ENV['PACKAGECLOUD_TOKEN']
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
        $stdout.puts "Cannot create security release repository: #{result.response}"
        false
      end
    end
  end

  def promote_packages(secret_repo)
    packages = client.list_packages(secret_repo)
    if packages.succeeded
      packages.response.count
      packages.response.map do |p|
        distro, version = p['distro_version'].split('/')
        client.promote_package(secret_repo, distro, version, p['filename'], public_repo_for_package(p['filename']))
      end
    else
      $stdout.puts "Cannot find the security release repository"
    end
  end

  def public_repo_for_package(filename)
    pkg = PackageVersion.new(filename)
    if pkg.ce?
      GITLAB_CE_PUBLIC_REPO
    else
      GITLAB_EE_PUBLIC_REPO
    end
  end
end
