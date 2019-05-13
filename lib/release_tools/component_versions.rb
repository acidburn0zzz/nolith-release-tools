# frozen_string_literal: true

module ReleaseTools
  class ComponentVersions
    FILES = %w[
      GITALY_SERVER_VERSION
      GITLAB_PAGES_VERSION
      GITLAB_SHELL_VERSION
      GITLAB_WORKHORSE_VERSION
    ].freeze

    def self.get(project, commit_id)
      versions = { 'VERSION' => commit_id }

      FILES.each_with_object(versions) do |file, memo|
        memo[file] = ReleaseTools::GitlabClient
          .file_contents(project.path, file, commit_id)
          .chomp
      end
    end

    def self.update_omnibus(target_branch, version_map)
      return if SharedStatus.dry_run?

      actions = version_changes(target_branch, version_map).map do |filename, contents|
        {
          action: 'update',
          file_path: "/#{filename}",
          content: "#{contents}\n"
        }
      end

      if actions.empty?
        return ReleaseTools::GitlabClient.commit(
          ReleaseTools::Project::OmnibusGitlab,
          ref: target_branch
        )
      end

      ReleaseTools::GitlabClient.create_commit(
        ReleaseTools::Project::OmnibusGitlab,
        target_branch,
        'Update component versions',
        actions
      )
    end

    def self.version_changes(target_branch, version_map)
      project = ReleaseTools::Project::OmnibusGitlab
      version_map.reject do |filename, contents|
        ReleaseTools::GitlabClient.file_contents(
          project.path,
          "/#{filename}",
          target_branch
        ).chomp == contents
      end
    end
  end
end
