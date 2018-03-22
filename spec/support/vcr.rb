require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures'
  c.configure_rspec_metadata!
  c.default_cassette_options = { record: :new_episodes }
  c.hook_into :webmock

  %w[API_AUTH_TOKEN PRIVATE_TOKEN].each do |val|
    c.filter_sensitive_data("[GITLAB_API_#{val}]") { ENV["GITLAB_API_#{val}"] }
  end
end
