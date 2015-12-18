require 'rubygems'
require 'bundler/setup'
require 'fileutils'
require 'colorize'

require_relative 'lib/version'
require_relative 'lib/monthly_issue'
require_relative 'lib/patch_issue'
require_relative 'lib/regression_issue'
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

def create_or_show_issue(issue)
  if issue.exists?
    puts "--> Issue \"#{issue.title}\" already exists.".red
    puts "    #{issue.url}"
    exit 1
  else
    remote = issue.create
    puts "--> Issue \"#{issue.title}\" created.".green
    puts "    #{Client.issue_url(remote)}"
  end
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

desc "Create the monthly release issue"
task :monthly_issue, [:version] do |t, args|
  version = get_version(args)
  issue = MonthlyIssue.new(version)

  create_or_show_issue(issue)
end

desc "Create the regression tracking issue"
task :regression_issue, [:version] do |t, args|
  version = get_version(args)
  issue = RegressionIssue.new(version)

  create_or_show_issue(issue)
end

desc "Create a patch issue"
task :patch_issue, [:version] do |t, args|
  version = get_version(args)
  issue = PatchIssue.new(version)

  create_or_show_issue(issue)
end
