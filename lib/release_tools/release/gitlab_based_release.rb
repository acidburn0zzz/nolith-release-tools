# frozen_string_literal: true

module ReleaseTools
  module Release
    class GitlabBasedRelease < BaseRelease
      class VersionFileDoesNotExistError < StandardError; end

      def initialize(version, opts = {})
        super(version, opts)

        raise ArgumentError, "missing gitlab_repo_path" unless gitlab_repo_path
      end

      def read_file_from_gitlab_repo(file_name)
        gitlab_file_path = File.join(gitlab_repo_path, file_name)

        ensure_version_file_exists!(gitlab_file_path)

        File.read(gitlab_file_path).strip
      end

      def ensure_version_file_exists!(filename)
        raise VersionFileDoesNotExistError.new(filename) unless File.exist?(filename)
      end

      def gitlab_repo_path
        options[:gitlab_repo_path]
      end
    end
  end
end
