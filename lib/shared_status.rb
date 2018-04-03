module SharedStatus
  extend self

  def dry_run?
    ENV['TEST'].present?
  end

  def security_release?
    ENV['SECURITY'] == 'true'
  end

  def user
    `git config --get user.name`.strip
  end
end
