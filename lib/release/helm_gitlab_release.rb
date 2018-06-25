require_relative 'base_release'
require_relative '../project/helm_gitlab'
require_relative '../helm/chart_file'
require_relative '../helm_gitlab_version'
require_relative '../helm_chart_version'

module Release
  class HelmGitlabRelease < BaseRelease
    attr_reader :gitlab_version

    def initialize(version, gitlab_version, opts = {})
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

    private

    def prepare_release
      $stdout.puts "Prepare repository...".colorize(:green)
      repository.pull_from_all_remotes('master')
      populate_version
      repository.ensure_branch_exists(stable_branch)
      repository.pull_from_all_remotes(stable_branch)
    end

    def execute_release
      repository.ensure_branch_exists(stable_branch)
      bump_versions
      push_ref('branch', stable_branch)
      push_ref('branch', 'master')

      # Do not tag when passed a RC gitlab version
      unless gitlab_version && gitlab_version.rc?
        create_tag(tag)
        push_ref('tag', tag)
      end
    end

    def after_release
      commit_master_versions

      super
    end

    def bump_versions
      bump_version(version, gitlab_version)
    end

    def bump_version(chart_version, app_version = nil)
      args = ['--include-subcharts']
      args << "--chart-version #{chart_version}"
      args << "--app-version=#{app_version}" if app_version && app_version.valid?

      message = ["Update Chart Version to #{chart_version}"]
      message << "Update Gitlab Version to #{app_version}" if app_version && app_version.valid?
      $stdout.puts "#{message.join(' ')}...".colorize(:green)
      out, status = run_update_version(args)

      raise(StandardError.new(out)) unless status.success?

      repository.commit(Dir.glob(File.join(repository.path, '**', 'Chart.yaml')), message: message.join("\n"))
    end

    def commit_master_versions
      return unless version.release? && version.patch.zero?

      repository.ensure_branch_exists('master')
      repository.pull_from_all_remotes('master')
      bump_version(version)
      push_ref('branch', 'master')
    end

    def run_update_version(args)
      Dir.chdir(repository.path) do
        final_args = ['./scripts/manage_version.rb', *args]
        $stdout.puts "[#{Time.now}] [#{Dir.pwd}] #{final_args.join(' ')}".colorize(:cyan)

        cmd_output = `#{final_args.join(' ')} 2>&1`

        [cmd_output, $CHILD_STATUS]
      end
    end

    def populate_version
      return if version && version.valid?

      # The 11.0.0 release marks the beta release of the charts.
      # We will bump the chart version from 0.1.x to 0.2.0 for the beta, instead of
      # bumping to 1.0.0
      if gitlab_version <= HelmGitlabVersion.new('11.0.0')
        return @version = HelmChartVersion.new('0.2.0')
      end

      # Use the previous tag to determine the old chart version for a patch release
      if gitlab_version.patch?
        tags = repository.tags(sort: '-v:refname')
        base_branch = tags.first if tags
      else
        base_branch = 'master'
      end

      unless base_branch
        raise StandardError.new("Failed to find a previous tag to determine chart version")
      end

      unless repository.fetch(base_branch)
        raise StandardError.new("Failed to fetch #{base_branch} while trying to find previous chart version.")
      end

      repository.ensure_branch_exists(base_branch)

      # Diff the old chart data with the new release to find the new chart version
      chart = Helm::ChartFile.new(File.join(repository.path, 'Chart.yaml'))
      @version = gitlab_version.new_chart_version(chart.version, chart.app_version)
    end
  end
end
