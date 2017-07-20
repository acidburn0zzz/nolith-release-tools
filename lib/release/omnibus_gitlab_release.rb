require_relative 'base_release'
require_relative '../omnibus_gitlab_version'
require_relative '../project/omnibus_gitlab'
require 'time'

module Release
  class OmnibusGitLabRelease < BaseRelease
    class VersionFileDoesNotExistError < StandardError; end
    class TemplateFileDoesNotExistError < StandardError; end
    class VersionStringNotFoundError < StandardError; end
    class SecurityReleaseInProgressError < StandardError; end

    # Number of minutes we will be able to reuse the same security repository.
    SECURITY_REPO_GRACE_PERIOD = 24 * 60 * 60

    def promote_security_release
      $stdout.puts 'Promoting security release to public...'.colorize(:green)

      if repo_variable
        packagecloud.promote_packages(repo_variable)
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

      # Prevent different security releases from running at the same time
      if release_in_progress?(repo_variable)
        raise SecurityReleaseInProgressError, "Existing security release defined in CI: #{repo_variable} (cannot start new one: #{security_repository})."
      end

      # Use the existing security repository if we have one set
      repository = repo_variable || security_repository

      # Create packagecloud repositories or re-use existing ones
      if packagecloud.create_secret_repository(repository)
        $stdout.puts "Created repository in packagecloud: #{repository}".colorize(:green)
      else
        $stdout.puts "Using existing packagecloud repository: #{repository}".colorize(:green)
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
      if security_release? && (version.major < 9 || version.major == 9 && version.minor < 4)
        prepare_security_release
      end

      super
    end

    def after_release
      bump_container_versions(stable_branch)
      bump_container_versions('master')
      push_ref('branch', stable_branch)
      push_ref('branch', 'master')

      super
    end

    def repo_variable
      return @repo_variable if defined?(@repo_variable)

      @repo_variable = GitlabDevClient.fetch_repo_variable
    end

    def security_repository
      @security_repository ||= "security-#{Time.now.utc.strftime('%Y%m%dT%H%MZ')}"
    end

    def release_in_progress?(repo_variable)
      return false unless repo_variable

      time_limit = repo_variable_time(repo_variable) + SECURITY_REPO_GRACE_PERIOD

      Time.now.utc > time_limit
    end

    def repo_variable_time(repo_variable)
      Time.parse(repo_variable.split('-').last)
    end

    def packagecloud
      @packagecloud ||= PackagecloudClient.new
    end

    def remotes
      Project::OmnibusGitlab.remotes(dev_only: options[:security])
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

    def bump_container_versions(branch)
      repository.ensure_branch_exists(branch)
      bump_version_in_openshift_template
    end

    def version_from_container_template(file_path)
      unless File.exist?(file_path)
        raise TemplateFileDoesNotExistError.new(file_path)
      end

      file_version = File.open(file_path) { |f| f.read.match(%r{gitlab/gitlab-ce:(\d+\.\d+\.\d+-ce\.\d+)})[1] }
      version_class.new(file_version.tr('-', '+'))
    end

    def bump_version_in_openshift_template
      return if version.ee? || version.rc?

      file_path = File.join(repository.path, 'docker/openshift-template.json')
      openshift_version = version_from_container_template(file_path)
      unless openshift_version.valid?
        raise VersionStringNotFoundError.new("#{openshift_version} in #{file_path}")
      end

      # Only bump the version if newer than what is already in the template
      return unless version > openshift_version

      content = File.read(file_path)
      content.sub!(%r{(?<!'")gitlab/gitlab-ce:\d+\.\d+\.\d+-ce\.\d+(?!'")}, "gitlab/gitlab-ce:#{version.to_docker}")
      content.gsub!(/(?<!'")gitlab-\d+\.\d+\.\d+(?!'")/, "gitlab-#{version.to_patch}")
      repository.write_file(file_path, content)
      repository.commit(file_path, "Update #{file_path} to #{version.to_docker}")
    end
  end
end
