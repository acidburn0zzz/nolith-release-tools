module SharedStatus
  extend self

  def dry_run?
    ENV['TEST'].present?
  end
end
