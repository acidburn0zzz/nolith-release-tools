require 'date'

require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/date'
require 'active_support/core_ext/date_time'
require 'active_support/core_ext/integer'
require 'active_support/core_ext/numeric'

module Release
  # Get the Date of the next release
  #
  # Defaults to the 22nd of the current month, or next month if the current one
  # is half over.
  #
  # Returns a Date
  def self.next_date
    today = Date.today

    next_date = Date.new(today.year, today.month, 22)
    next_date = next_date.next_month if today.day >= 15

    next_date
  end
end
