# frozen_string_literal: true

module ReleaseTools
  module Release
    class HelmGitlabRelease < BaseRelease
      attr_reader :gitlab_version

      def initialize(version, gitlab_version = nil, opts = {})
        @version = version_class.new(version) if version
        @gitlab_version = HelmGitlabVersion.new(gitlab_version) if gitlab_version
        @options = opts
      end

      def version_class
        HelmChartVersion
      end

      def remotes
        Project::HelmGitlab.remotes
      end

      def version_manager
        @version_manager ||= Helm::VersionManager.new(repository)
      end

      private

      def prepare_release
        $stdout.puts "Prepare repository...".colorize(:green)
        repository.pull_from_all_remotes('master')
        @version ||= version_manager.next_version(gitlab_version)
        repository.ensure_branch_exists(stable_branch)
        repository.pull_from_all_remotes(stable_branch)
      end

      def before_execute_hook
        repository.ensure_branch_exists(stable_branch)
        add_changelog
        compile_changelog

        super
      end

      def execute_release
        repository.ensure_branch_exists(stable_branch)
        bump_versions

        push_ref('branch', stable_branch)
        push_ref('branch', 'master')

        # Do not tag when passed a RC gitlab version
        unless version_manager.parse_chart_file.app_version.rc?
          create_tag(tag, message: "Version #{tag} - contains GitLab EE #{gitlab_version}")
          push_ref('tag', tag)
        end
      end

      def after_release
        commit_master_versions

        super
      end

      def compile_changelog
        app_version = gitlab_version || version_manager.parse_chart_file.app_version
        return if app_version.rc?

        Changelog::Manager.new(repository.path).release(version)
      rescue Changelog::NoChangelogError => ex
        $stderr.puts "Cannot perform changelog update for #{version} on " \
          "#{ex.changelog_path}".colorize(:red)
      end

      def bump_versions
        bump_version(version, gitlab_version)
      end

      def bump_version(chart_version, app_version = nil)
        args = ['--include-subcharts']
        args << "--chart-version #{chart_version}"
        args << "--app-version=#{app_version}" if app_version && app_version.valid?
        args << "--gitlab-repo=#{Project::GitlabEe.dev_path}"

        message = ["Update Chart Version to #{chart_version}"]
        message << "Update Gitlab Version to #{app_version}" if app_version && app_version.valid?
        $stdout.puts "#{message.join(' ')}...".colorize(:green)

        run_update_version(args)

        charts = Dir.glob(File.join(repository.path, '**', 'Chart.yaml'))
        version_mappings = Dir.glob(File.join(repository.path, '**', 'version_mappings.md'))

        repository.commit(charts + version_mappings, message: message.join("\n"))
      end

      def commit_master_versions
        return unless version_manager.parse_chart_file.app_version.release?

        repository.ensure_branch_exists('master')
        repository.pull_from_all_remotes('master')

        bump_versions
        push_ref('branch', 'master')
      end

      def run_update_version(args)
        Dir.chdir(repository.path) do
          final_args = ['./scripts/manage_version.rb', *args]
          $stdout.puts "[#{Time.now}] [#{Dir.pwd}] #{final_args.join(' ')}".colorize(:cyan)

          cmd_output = `#{final_args.join(' ')} 2>&1`

          raise(StandardError.new(cmd_output)) unless $CHILD_STATUS.success?
        end
      end

      def add_changelog
        return unless gitlab_version && gitlab_version.release?

        message = "Update GitLab Version to #{gitlab_version}"

        Dir.chdir(repository.path) do
          final_args = ['./bin/changelog', '-t other', message]
          $stdout.puts "[#{Time.now}] [#{Dir.pwd}] #{final_args.join(' ')}".colorize(:cyan)

          cmd_output = `#{final_args.join(' ')} 2>&1`

          raise(StandardError.new(cmd_output)) unless $CHILD_STATUS.success?
        end

        repository.commit(Dir.glob(File.join(repository.path, 'changelogs', 'unreleased', '*.yml')), message: "Changelog - #{message}")
      end
    end
  end
end
