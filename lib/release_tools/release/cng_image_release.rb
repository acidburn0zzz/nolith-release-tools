# frozen_string_literal: true

module ReleaseTools
  module Release
    class CNGImageRelease < BaseRelease
      class VersionFileDoesNotExistError < StandardError; end
      def remotes
        Project::CNGImage.remotes
      end

      private

      def bump_versions
        target_file = File.join(repository.path, 'ci_files/variables.yml')

        yaml_contents = YAML.load_file(target_file)
        yaml_contents['variables'].merge!(component_versions)

        File.open(target_file, 'w') do |f|
          f.write(YAML.dump(yaml_contents))
        end

        repository.commit(target_file, message: "Update #{target_file} for #{version}")
      end

      def component_versions
        components = {}

        # These components always track the GitLab release version
        %w[
          GITLAB_VERSION
          GITLAB_REF_SLUG
          GITLAB_ASSETS_TAG
        ].each { |key| components[key] = version_string(version) }

        # These components specify their versions independently
        %w[
          GITALY_SERVER_VERSION
          GITLAB_ELASTICSEARCH_INDEXER_VERSION
          GITLAB_SHELL_VERSION
          GITLAB_WORKHORSE_VERSION
        ].each { |key| components[key] = version_string_from_file(key) }

        components
      end

      def version_string(version)
        "v#{version}"
      end

      def read_file_from_gitlab_repo(file_name)
        gitlab_file_path = File.join(options[:gitlab_repo_path], file_name)
        unless File.exist?(gitlab_file_path)
          raise VersionFileDoesNotExistError.new(gitlab_file_path)
        end

        File.read(gitlab_file_path).strip
      end

      def version_string_from_file(file_name)
        version_string(read_file_from_gitlab_repo(file_name))
      end
    end
  end
end
