require 'rubygems'
require 'bundler/setup'
require 'fileutils'
require 'colorize'

require_relative 'lib/version'
require_relative 'lib/release'
require_relative 'lib/remotes'
require_relative 'lib/sync'

desc "Create release"
task :release, [:version] do |t, args|
  version = args[:version]

  unless Version.valid?(version)
    puts 'You should pass version argument in next format: 7.5.0.rc1 or 7.6.2'
    exit 1
  end

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

  unless ENV['CI'] == 'false'
    puts "CI release".colorize(:blue)
    Release.new(version, Remotes.ci_remotes).execute
  else
    puts 'Skipping release for CI'.colorize(:red)
  end
end

desc "Sync master branch in remotes"
task :sync do
  Sync.new(Remotes.ce_remotes).execute
  Sync.new(Remotes.ee_remotes).execute
  Sync.new(Remotes.ci_remotes).execute
end
