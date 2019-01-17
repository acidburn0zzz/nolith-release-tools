# This ensures we don't push to the repo during tests
ENV['TEST'] = 'true'

# Stub API tokens
ENV['DEV_API_PRIVATE_TOKEN'] = 'test'
ENV['GITLAB_API_PRIVATE_TOKEN'] = 'test'
ENV['GITLAB_API_APPROVAL_TOKEN'] = 'test'
ENV['OPS_API_PRIVATE_TOKEN'] = 'test'

# SimpleCov needs to be loaded before everything else
require_relative 'support/simplecov'

require_relative '../init'
require 'active_support/core_ext/string/strip'
require 'active_support/core_ext/object/inclusion'
require 'rspec-parameterized'

Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'

  unless ENV['CI']
    config.example_status_persistence_file_path = './spec/examples.txt'
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.around(:example, :silence_stdout) do |example|
    expect { example.run }.to output.to_stdout
  end

  config.around(:example, :silence_stderr) do |example|
    expect { example.run }.to output.to_stderr
  end
end
