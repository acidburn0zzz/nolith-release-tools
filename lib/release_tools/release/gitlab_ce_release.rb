# frozen_string_literal: true

module ReleaseTools
  module Release
    class GitlabCeRelease < BaseRelease
      private

      def remotes
        Project::GitlabCe.remotes
      end

      def before_execute_hook
        compile_changelog

        super
      end

      def after_execute_hook
        Release::OmnibusGitlabRelease.new(
          version.to_omnibus(ee: version.ee?),
          options.merge(gitlab_repo_path: repository.path)
        ).execute
      end

      def after_release
        tag_next_minor_pre_version

        super
      end

      def compile_changelog
        return if version.rc?

        Changelog::Manager.new(repository.path).release(version)
      rescue Changelog::NoChangelogError => ex
        $stderr.puts "Cannot perform changelog update for #{version} on " \
          "#{ex.changelog_path}".colorize(:red)
      end

      def tag_next_minor_pre_version
        return unless version.release? && version.patch.zero?

        repository.ensure_branch_exists('master')
        repository.pull_from_all_remotes('master')
        bump_version('VERSION', "#{version.next_minor}-pre")
        push_ref('branch', 'master')

        next_minor_pre_tag = "v#{version.next_minor}.pre"
        create_tag(next_minor_pre_tag)
        push_ref('tag', next_minor_pre_tag)
      end
    end
  end
end
