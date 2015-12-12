require 'rubygems'
require 'bundler/setup'
require 'fileutils'
require 'colorize'

require_relative 'lib/version'
require_relative 'lib/monthly_issue'
require_relative 'lib/release'
require_relative 'lib/remotes'
require_relative 'lib/sync'

def get_version(args)
  version = Version.new(args[:version])

  unless version.valid?
    puts "Version number must be in the following format: X.Y.Z.rc1 or X.Y.Z".colorize(:red)
    exit 1
  end

  version
end

desc "Create release"
task :release, [:version] do |t, args|
  version = get_version(args)

  unless ENV['CE'] == 'false'
    puts "CE release".colorize(:blue)
    Release.new(version, Remotes.ce_remotes).execute
  else
    puts 'Skipping release for CE'.colorize(:red)
  end

  unless ENV['EE'] == 'false'
    puts "EE release".colorize(:blue)
    Release.new(version + '-ee', Remotes.ee_remotes).execute
  else
    puts 'Skipping release for EE'.colorize(:red)
  end
end

desc "Sync master branch in remotes"
task :sync do
  Sync.new(Remotes.ce_remotes).execute
  Sync.new(Remotes.ee_remotes).execute
end

desc "Display monthly release issue template"
task :monthly_issue, [:version] do |t, args|
  version = get_version(args)
  issue = MonthlyIssue.new(version)

  puts issue.description
end
