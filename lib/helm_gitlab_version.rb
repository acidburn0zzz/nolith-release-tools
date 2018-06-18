require_relative 'version'
require_relative 'helm_chart_version'

class HelmGitlabVersion < Version
  def get_new_chart_version(old_chart_version, old_gitlab_version)
    old_chart_version = HelmChartVersion.new(old_chart_version)
    old_gitlab_version = HelmGitlabVersion.new(old_gitlab_version)

    app_change = diff(old_gitlab_version)

    # If the old gitlab version isn't semver, we are likely branching from master
    # and are branching to prep for release. Bump the chart version based on the type
    # of release we are doing
    unless old_gitlab_version.valid?
      if minor.zero? && patch.zero?
        app_change = Version::MAJOR
      elsif patch.zero?
        app_change = Version::MINOR
      else
        app_change = Version::PATCH
      end
    end

    case app_change
    when Version::MAJOR
      HelmChartVersion.new("#{old_chart_version.major + 1}.0.0")
    when Version::MINOR
      HelmChartVersion.new(old_chart_version.next_minor)
    when Version::PATCH
      HelmChartVersion.new(old_chart_version.next_patch)
    else
      chart.version
    end
  end

  private

  def custom_release_rule
    # The 11.0.0 release marks the beta release of the charts.
    # We will bump the chart version from 0.1.x to 0.2.0 for the beta, instead of
    # bumping to 1.0.0, which would
  end
end
