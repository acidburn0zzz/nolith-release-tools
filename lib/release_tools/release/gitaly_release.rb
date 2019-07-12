# frozen_string_literal: true

module ReleaseTools
  module Release
    class GitalyRelease < BaseRelease
      class VersionFileDoesNotExistError < StandardError; end

      def remotes
        Project::Gitaly.remotes
      end

      def before_execute_hook
        unless version.rc?
          ReleaseTools::Changelog::Manager.new(repository.path, 'CHANGELOG.md').release(version)
        end
      rescue ReleaseTools::Changelog::NoChangelogError => ex
        warn "Cannot perform changelog update for #{version} on " \
          "#{ex.changelog_path}".colorize(:red)
      end

      def after_execute_hook
        # This hook could be leveraged to create a merge request on GitLab
        # to write the new version in their GITALY_SERVER_VERSION file.
        # https://gitlab.com/gitlab-org/release-tools/issues/298
      end
    end
  end
end
