require_relative 'base_release'
require_relative '../omnibus_gitlab_version'

module Release
  class OmnibusGitLabRelease < BaseRelease
    class VersionFileDoesNotExistError < StandardError; end

    private

    def remotes
      Remotes.omnibus_gitlab_remotes
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
     files << 'GITLAB_PAGES_VERSION' if version.ee? && expect_pages_version_file?
     files << 'VERSION' # Always update VERSION last
     files
    end

    def expect_pages_version_file?
      version.major > 8 || version.major == 8 && version.minor > 4
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
