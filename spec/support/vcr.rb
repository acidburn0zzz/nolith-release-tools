require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures'
  c.configure_rspec_metadata!
  c.default_cassette_options = { record: :new_episodes }
  c.hook_into :webmock

  c.filter_sensitive_data('[GITLAB_API_PRIVATE_TOKEN]') { ENV['GITLAB_API_PRIVATE_TOKEN'] }
  c.filter_sensitive_data('[DEV_API_PRIVATE_TOKEN]') { ENV['DEV_API_PRIVATE_TOKEN'] }
end
