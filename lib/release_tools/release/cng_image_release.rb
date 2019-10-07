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
        yaml_contents['variables'].merge!(
          'GITLAB_VERSION' => version_string(version),
          'GITALY_VERSION' => version_string_from_file('GITALY_SERVER_VERSION'),
          'GITLAB_SHELL_VERSION' => version_string_from_file('GITLAB_SHELL_VERSION'),
          'GITLAB_WORKHORSE_VERSION' => version_string_from_file('GITLAB_WORKHORSE_VERSION'),
          'GITLAB_REF_SLUG' => version_string(version),
          'GITLAB_ASSETS_TAG' => version_string(version)
        )

        File.open(target_file, 'w') do |f|
          f.write(YAML.dump(yaml_contents))
        end

        repository.commit(target_file, message: "Update #{target_file} for #{version}")
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
