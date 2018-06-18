require_relative 'base_release'
require_relative '../project/helm_gitlab'
require_relative '../helm/chart_file'

module Release
  class HelmGitlabRelease < BaseRelease
    attr_reader :gitlab_version

    def initialize(version, gitlab_version, opts = {})
      @version = version_class.new(version)
      @gitlab_version = version_class.new(gitlab_version)
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
      # push_ref('branch', stable_branch)
      # push_ref('branch', 'master')
      # create_tag(tag)
      # push_ref('tag', tag)
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

      $stdout.puts "Update chart version: #{chart_version} gitlab version: #{app_version}...".colorize(:green)
      out, status = run_update_version(args)

      status.success? || raise(StandardError.new(out))
    end

    def commit_master_versions
      return unless version.release? && version.patch.zero?

      repository.ensure_branch_exists('master')
      repository.pull_from_all_remotes('master')
      bump_version(version)
      # push_ref('branch', 'master')
    end

    def run_update_version(args)
      repository.in_path do
        final_args = ['./scripts/manage_version.rb', *args]
        $stdout.puts "[#{Time.now}] [#{Dir.pwd}] #{final_args.join(' ')}".colorize(:cyan)

        cmd_output = `#{final_args.join(' ')} 2>&1`

        [cmd_output, $CHILD_STATUS]
      end
    end

    def populate_version
      return if version.valid?

      # The 11.0.0 release marks the beta release of the charts.
      # We will bump the chart version from 0.1.x to 0.2.0 for the beta, instead of
      # bumping to 1.0.0
      if gitlab_version <= HelmGitlabVersion.new('11.0.0')
        return @version = HelmChartVersion.new('0.2.0')
      end

      previous_tag = gitlab_version.previous_tag

      # Use the previous patch to determine the old chart version for a patch release
      if gitlab_version.patch? && repository.fetch(previous_tag) && repository.checkout_branch(previous_tag)
        base_branch = previous_tag
      else
        base_branch = 'master'
      end

      unless repository.checkout_branch(base_branch)
        raise StandardError.new("Failed to checkout #{base_branch} while trying to find previous chart version.")
      end

      # Diff the old chart data with the new release to find the new chart version
      chart = ChartFile.new(File.join(repository.path, 'Chart.yaml'))
      @version = gitlab_version.get_new_chart_version(chart.version, chart.app_version)
    end
  end
end
