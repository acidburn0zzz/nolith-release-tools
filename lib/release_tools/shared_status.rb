# frozen_string_literal: true

module ReleaseTools
  module SharedStatus
    extend self

    def dry_run?
      ENV['TEST'].present?
    end

    def critical_security_release?
      ENV['SECURITY'] == 'critical'
    end

    def security_release?
      ENV['SECURITY'].present?
    end

    def user
      `git config --get user.name`.strip
    end
  end
end
