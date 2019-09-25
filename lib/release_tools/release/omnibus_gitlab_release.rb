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
        return if version.rc? || version.ee?

        logger.info('Compiling changelog', version: version)

        ReleaseTools::Changelog::Manager.new(repository.path, 'CHANGELOG.md').release(version)
      rescue ReleaseTools::Changelog::NoChangelogError => ex
        logger.error('Changelog update failed', version: version, path: ex.changelog_path)
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
        files = %w[
          GITALY_SERVER_VERSION
          GITLAB_PAGES_VERSION
          GITLAB_SHELL_VERSION
          GITLAB_WORKHORSE_VERSION
        ]

        files << 'VERSION' # Always update VERSION last
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
