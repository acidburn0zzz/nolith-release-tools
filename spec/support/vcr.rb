require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures'
  c.configure_rspec_metadata!
  c.default_cassette_options = { record: :new_episodes }
  c.hook_into :webmock

  %w[API_AUTH_TOKEN PRIVATE_TOKEN].each do |val|
    c.filter_sensitive_data("[GITLAB_API_#{val}]") { ENV["GITLAB_API_#{val}"] }
    c.filter_sensitive_data("[GITLAB_DEV_API_#{val}]") { ENV["GITLAB_DEV_API_#{val}"] }
  end

  c.filter_sensitive_data("[PACKAGECLOUD_TOKEN]") { ENV["PACKAGECLOUD_TOKEN"] }
  c.filter_sensitive_data('[PACKAGECLOUD_ENCODED_TOKEN]') { Base64.strict_encode64("#{ENV['PACKAGECLOUD_TOKEN']}:") }
end
