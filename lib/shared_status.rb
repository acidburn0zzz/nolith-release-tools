module SharedStatus
  extend self

  def dry_run?
    ENV['TEST'].present?
  end

  def security_release?
    ENV['SECURITY'].present?
  end

  def user
    `git config --get user.name`.strip
  end
end
