# frozen_string_literal: true

require 'version_sorter'

namespace :prepare do
  desc 'Prepare the next security release'
  task :security_release do
    versions = ReleaseTools::VersionClient
      .versions
      .collect(&:version)

    monthlies = VersionSorter.rsort(versions).uniq do |version|
      version.split('.').take(2)
    end.take(3)

    monthlies.each do |v|
      version = ReleaseTools::Version.new(v)

      puts "#{version} => #{version.next_patch}"
    end
  end
end
