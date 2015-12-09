require 'date'
require 'erb'

require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/date'
require 'active_support/core_ext/date_time'
require 'active_support/core_ext/integer'
require 'active_support/core_ext/numeric'
require 'weekdays'

# MonthlyPost
#
# Handles chores related to monthly releases of GitLab CE and EE.
#
# Example:
#
#   version = Version.new('8.3.0')
#
#   # Uses the 22nd of the current month as the release date by default
#   post = MonthlyPost.new(version)
#   post.release_date.to_s       # => "2015-12-22"
#   post.rc1_version             # => "8.3.0.rc1"
#   post.stable_branch           # => "8-3-stable"
#   post.stable_branch(ee: true) # => "8-3-stable-ee"
#
#   # Override the default release date
#   post = MonthlyPost.new(version, Date.new(2015, 11, 22))
#   post.release_date.to_s # => "2015-11-22"
class MonthlyPost
  def self.next_release_date
    today = Date.today

    Date.new(today.year, today.month, 22)
  end

  attr_reader :release_date, :version

  def initialize(version, release_date = self.class.next_release_date)
    @version      = version
    @release_date = release_date
  end

  def post_title
    "Release #{version.to_minor}"
  end

  def render
    ERB.new(template).result(binding)
  end

  def ordinal_date(weekdays_before_release)
    weekdays_before_release
      .weekdays_ago(release_date)
      .day
      .ordinalize
  end

  def rc1_version
    "#{version.to_patch}.rc1"
  end

  def stable_branch(ee: false)
    version.branch_name(force_ee: ee)
  end

  private

  def template
    File.read(template_path)
  end

  def template_path
    File.expand_path('../templates/monthly.txt.erb', __dir__)
  end
end
