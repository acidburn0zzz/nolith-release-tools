# frozen_string_literal: true

module ReleaseTools
  module Release
    class OmnibusGitlabRelease < BaseRelease
      class VersionFileDoesNotExistError < StandardError; end
      class TemplateFileDoesNotExistError < StandardError; end
      class VersionStringNotFoundError < StandardError; end

      # Number of minutes we will be able to reuse the same security repository.
      SECURITY_REPO_GRACE_PERIOD = 24 * 60 * 60

      private

      def after_release
        repository.ensure_branch_exists(stable_branch)
        repository.ensure_branch_exists('master')
        push_ref('branch', stable_branch)
        push_ref('branch', 'master')

        super
      end

      def before_execute_hook
        repository.ensure_branch_exists(stable_branch)
        compile_changelog
      end

      def compile_changelog
        return if version.rc?

        ReleaseTools::Changelog::Manager.new(repository.path, 'CHANGELOG.md').release(version.to_patch)
      rescue ReleaseTools::Changelog::NoChangelogError => ex
        $stderr.puts "Cannot perform changelog update for #{version} on " \
          "#{ex.changelog_path}".colorize(:red)
        $stderr.puts "Received error: #{ex.message}".colorize(:red)
      end

      def remotes
        ReleaseTools::Project::OmnibusGitlab.remotes
      end

      def version_class
        ReleaseTools::OmnibusGitlabVersion
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
end
