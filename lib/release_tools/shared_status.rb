# frozen_string_literal: true

module ReleaseTools
  module SharedStatus
    extend self

    def dry_run?
      ENV['TEST'].present? || Feature.enabled?(:force_dry_run)
    end

    def security_release?
      ENV['SECURITY'].present?
    end

    def user
      `git config --get user.name`.strip
    end
  end
end
