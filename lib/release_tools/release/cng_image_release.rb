# frozen_string_literal: true

require_relative '../support/ubi_helper'

module ReleaseTools
  module Release
    class CNGImageRelease < GitlabBasedRelease
      include ReleaseTools::Support::UbiHelper

      def remotes
        Project::CNGImage.remotes
      end

      def tag
        options[:ubi] && ubi?(version) ? ubi_tag(version, options[:ubi_version]) : super
      end

      private

      def bump_versions
        logger.trace('bump versions')
        target_file = File.join(repository.path, 'ci_files/variables.yml')

        yaml_contents = YAML.load_file(target_file)
        yaml_contents['variables'].merge!(component_versions)

        File.open(target_file, 'w') do |f|
          f.write(YAML.dump(yaml_contents))
        end

        # It's expected that the UBI image tag will have nothing to commit
        return if options[:ubi] && !repository.changes?(paths: 'ci_files/variables.yml')

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

        # These components specify their versions inside the Gemfile
        {
          mail_room: "MAILROOM_VERSION"
        }
        .each { |key, value| components[value] = ReleaseTools::ComponentVersions::GemVersion.get_from_file(options[:gitlab_repo_path], key) }

        logger.trace('components', components: components)

        components
      end

      def version_string(version)
        # Prepend 'v' if version is semver
        return "v#{version}" if /^\d+\.\d+\.\d+(-rc\d+)?(-ee)?$/.match?(version)

        version
      end

      def version_string_from_file(file_name)
        version_string(read_file_from_gitlab_repo(file_name))
      end
    end
  end
end
