require 'rubygems'
require 'bundler/setup'
require 'fileutils'

require_relative 'lib/version'
require_relative 'lib/release'
require_relative 'lib/sync'

desc "Create release"
task :release, [:version] do |t, args|
  version = args[:version]

  unless Version.valid?(version)
    puts 'You should pass version argument in next format: 7.5.0.rc1 or 7.6.2'
    exit 1
  end

  release = Release.new(version)
  release.execute
end

desc "Sync master branch in remotes"
task :sync do
  Sync.new.execute
end
