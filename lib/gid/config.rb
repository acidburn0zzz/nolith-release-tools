require 'ostruct'
require 'pathname'

Config = OpenStruct.new
Config.root = Pathname.new(File.expand_path('../..', __FILE__))
Config.log_file = Config.root.join('..', 'gid.log')
Config.archive_log_file = Config.root.join('..', 'gid.old.log')

Config.colors = true
Config.dry_run = ENV['GID_DRY_RUN'] || false

Config.ce_repo = Config.root.join('../../gitlab-development-kit/gitlab')
Config.ee_repo = Config.root.join('../../gitlab-development-kit-ee/gitlab')
Config.ce_project_id = 13_083
Config.ee_project_id = 278_964

[%w[gid output ** *.rb],
 %w[gid tasks ** *.rb],
 %w[gid git ** *.rb],
 %w[gid styles.rb]].each do |pattern|
  Dir.glob(Config.root.join(*pattern)).each { |file| require file }
end
