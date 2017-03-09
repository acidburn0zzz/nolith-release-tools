require_relative 'base_release'
require_relative '../omnibus_gitlab_version'

module Release
  class OmnibusGitLabRelease < BaseRelease
    class VersionFileDoesNotExistError < StandardError; end
    class AnotherSecurityReleaseInProgressError < StandardError; end

    def promote_security_release
      $stdout.puts 'Promoting security release to public...'.colorize(:green)

      if GitlabDevClient.fetch_repo_variable
        packagecloud.promote_packages(security_repository)
        $stdout.puts 'Finished package promotion!'.colorize(:green)

        GitlabDevClient.remove_repo_variable
        $stdout.puts 'Removed CI Variable for Security Releases'.colorize(:green)
      else
        $stdout.puts 'There are no releases pending promotion'.colorize(:red)
      end
    end

    private

    def prepare_security_release
      $stdout.puts 'Prepare security release...'.colorize(:green)

      repo_variable = GitlabDevClient.fetch_repo_variable
      # Prevent different security releases from running at the same time
      if repo_variable && repo_variable != security_repository
        raise SecurityReleaseInProgressError, "Existing security release defined in CI: #{repo_variable} (cannot start new one: #{security_repository})."
      end

      # Create packagecloud repositories or re-use existing ones
      if packagecloud.create_secret_repository(security_repository)
        $stdout.puts "Created repository in packagecloud: #{security_repository}".colorize(:green)
      else
        $stdout.puts "Using existing packagecloud repository: #{security_repository}".colorize(:green)
      end

      # Define CI variable with current security_repository name
      if repo_variable
        $stdout.puts "Repository name already defined in CI: #{repo_variable}".colorize(:green)
      else
        GitlabDevClient.create_repo_variable(security_repository)
        $stdout.puts "Defined repository name in CI as: #{security_repository}".colorize(:green)
      end
    end

    def before_execute_hook
      prepare_security_release if security_release?

      super
    end

    def security_repository
      version_repo = version.to_minor.tr('.', '-')
      "security-#{version_repo}-#{Digest::MD5.hexdigest(version_repo + packagecloud.token)}"
    end

    def packagecloud
      @packagecloud ||= PackagecloudClient.new
    end

    def remotes
      Remotes.remotes(:omnibus_gitlab, dev_only: options[:security])
    end

    def version_class
      OmnibusGitLabVersion
    end

    def bump_versions
      version_files.each do |file|
        bump_version(file, version_from_gitlab_repo(file))
      end
    end

    def version_files
      files = %w[GITLAB_SHELL_VERSION GITLAB_WORKHORSE_VERSION]
      files << 'GITLAB_PAGES_VERSION' if expect_pages_version_file?
      files << 'GITALY_SERVER_VERSION' if expect_gitaly_version_file?
      files << 'VERSION' # Always update VERSION last
      files
    end

    # GitLab pages was released in EE 8.3, and CE 8.17
    def expect_pages_version_file?
      if version.ee?
        version.major > 8 || version.major == 8 && version.minor > 4
      else
        version.major > 8 || version.major == 8 && version.minor > 16
      end
    end

    def expect_gitaly_version_file?
      version.major >= 9
    end

    def version_from_gitlab_repo(file_name)
      file_path = File.join(repository.path, file_name)
      unless File.exist?(file_path)
        raise VersionFileDoesNotExistError.new(file_path)
      end

      read_file_from_gitlab_repo(file_name)
    end

    def read_file_from_gitlab_repo(file_name)
      gitlab_file_path = File.join(options[:gitlab_repo_path], file_name)
      unless File.exist?(gitlab_file_path)
        raise VersionFileDoesNotExistError.new(gitlab_file_path)
      end

      File.read(gitlab_file_path).strip
    end
  end
end
