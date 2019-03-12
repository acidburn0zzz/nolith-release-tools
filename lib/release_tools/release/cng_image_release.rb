module ReleaseTools
  module Release
    class CNGImageRelease < BaseRelease
      def remotes
        Project::CNGImage.remotes
      end

      private

      def bump_versions
        target_file = File.join(repository.path, 'ci_files/variables.yml')

        yaml_contents = YAML.load_file(target_file)
        yaml_contents['variables']['GITLAB_VERSION'] = version
        yaml_contents['variables']['GITALY_VERSION'] = read_file_from_gitlab_repo('GITALY_SERVER_VERSION')
        yaml_contents['variables']['GITLAB_SHELL_VERSION'] = read_file_from_gitlab_repo('GITLAB_SHELL_VERSION')
        yaml_contents['variables']['GITLAB_WORKHORSE_VERSION'] = read_file_from_gitlab_repo('GITLAB_WORKHORSE_VERSION')
        yaml_contents['variables']['GITLAB_REF_SLUG'] = version
        yaml_contents['variables']['GITLAB_ASSETS_TAG'] = version

        File.open(target_file, 'w') do |f|
          f.write(YAML.dump(yaml_contents))
        end

        repository.commit(target_file, message: "Update #{target_file} for #{version}")
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
