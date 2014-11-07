require 'rubygems'
require 'bundler/setup'
require 'fileutils'

require_relative 'lib/version'
require_relative 'lib/release_candidate'

namespace :release do
  desc "Create RC1 from master"
  task :rc1, [:version] do |t, args|

    version = args[:version]
    unless Version.valid?(version)
      puts 'You should pass version argument in next format: 7.5.0'
      exit 1
    end

    release = ReleaseCandidate.new(version)
    release.execute
  end
end
