require 'active_support/inflector'

module TimeUtil
  extend self

  def time_ago(time, precision: 1)
    return unless time

    ago = duration((Time.now - time).to_i)
    short = ago.take(precision).join(', ')
    "#{short} ago"
  end

  def duration(delta)
    result = []

    [[60, 'second'],
     [60, 'minute'],
     [24, 'hour'],
     [365, 'day'],
     [999, 'year']]
      .inject(delta) do |length, (divisor, name)|
        quotient, remainder = length.divmod(divisor)
        period = remainder == 1 ? name : name.pluralize
        result.unshift("#{remainder} #{period}")
        break if quotient.zero?

        quotient
      end

    result
  end
  private_class_method :duration
end
