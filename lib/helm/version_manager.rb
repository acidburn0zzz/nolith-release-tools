module Helm
  class VersionManager
    attr_reader :repository, :version

    def initialize(repository)
      case repository
      when RemoteRepository
        @repository = repository
      else
        raise "Invalid repository: #{repository}"
      end
    end

    # Determine the next helm chart version by comparing the difference in gitlab
    # version between the last release and the new release
    def next_version(gitlab_version)
      # The 11.2.0 release marks the GA release of the charts.
      # We will bump the chart version from 0.3.x to 1.0.0 for the GA, instead of
      # bumping to 0.4.0
      if gitlab_version >= HelmGitlabVersion.new('11.2.0-rc1') && gitlab_version <= HelmGitlabVersion.new('11.2.0')
        return HelmChartVersion.new('1.0.0')
      end

      # switch to the latest branch, use the latest tag if we are doing a patch release
      checkout_latest(use_tag: gitlab_version.patch?)

      # Diff the old chart data with the new release to find the new chart version
      self.class.derive_chart_version(parse_chart_file, gitlab_version)
    end

    def self.derive_chart_version(old_chart_file, new_gitlab_version)
      old_chart_version = HelmChartVersion.new(old_chart_file.version)
      old_gitlab_version = HelmGitlabVersion.new(old_chart_file.app_version)

      # If the old gitlab version isn't semver, we are likely branching from master
      # and are branching to prep for release. Bump the chart version based on the type
      # of release we are doing
      app_change =
        if old_gitlab_version.valid?
          if old_gitlab_version > new_gitlab_version
            raise "Unable to derive chart version for an older GitLab #{new_gitlab_version}, " \
                  "GitLab is already version #{old_gitlab_version}"
          end

          new_gitlab_version.diff(old_gitlab_version)
        elsif new_gitlab_version.minor.zero? && new_gitlab_version.patch.zero?
          :major
        elsif new_gitlab_version.patch.zero?
          :minor
        else
          :patch
        end

      case app_change
      when :major
        HelmChartVersion.new("#{old_chart_version.major + 1}.0.0")
      when :minor
        HelmChartVersion.new(old_chart_version.next_minor)
      when :patch
        HelmChartVersion.new(old_chart_version.next_patch)
      else
        old_chart_version.dup
      end
    end

    def parse_chart_file
      Helm::ChartFile.new(File.join(repository.path, 'Chart.yaml'))
    end

    private

    def checkout_latest(use_tag: false)
      # Use the previous tag if requested
      if use_tag
        tags = repository.tags(sort: '-v:refname')
        base_branch = tags.first if tags
      else
        base_branch = 'master'
      end

      unless base_branch
        raise StandardError.new("Failed to find a previous tag.")
      end

      unless repository.fetch(base_branch)
        raise StandardError.new("Failed to fetch #{base_branch}.")
      end

      repository.ensure_branch_exists(base_branch)
    end
  end
end
