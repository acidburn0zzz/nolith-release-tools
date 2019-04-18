# frozen_string_literal: true

module WithoutDryRun
  # Unset the `TEST` environment variable that gets set by default
  def without_dry_run
    ClimateControl.modify(TEST: nil) do
      yield
    end
  end
end

RSpec.configure do |config|
  config.include WithoutDryRun
end
