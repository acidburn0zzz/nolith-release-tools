require 'date'

require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/date'
require 'active_support/core_ext/date_time'
require 'active_support/core_ext/integer'
require 'active_support/core_ext/numeric'
require 'weekdays'

require_relative 'base_issue'
require_relative 'release'

class MonthlyIssue < BaseIssue
  attr_reader :release_date, :version

  def initialize(version, release_date = Release.next_date)
    @version      = version
    @release_date = release_date
  end

  def title
    "Release #{version.to_minor}"
  end

  def labels
    'Release'
  end

  def ordinal_date(weekdays_before_release)
    weekdays_before_release
      .weekdays_ago(release_date)
      .day
      .ordinalize
  end

  protected

  def template_path
    File.expand_path('../templates/monthly.md.erb', __dir__)
  end
end
