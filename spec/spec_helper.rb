# This ensure we don't push to the repo during tests
ENV['TEST'] = 'true'

require 'simplecov'
SimpleCov.start

require 'active_support/core_ext/string/strip'

Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
