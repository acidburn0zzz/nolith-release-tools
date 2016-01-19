require 'colorize'

require_relative 'lib/version'
require_relative 'lib/monthly_issue'
require_relative 'lib/patch_issue'
require_relative 'lib/regression_issue'
require_relative 'lib/release'
require_relative 'lib/remotes'
require_relative 'lib/sync'


begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task default: :spec
rescue LoadError
  # no rspec available
end

def get_version(args)
  version = Version.new(args[:version])

  unless version.valid?
    puts "Version number must be in the following format: X.Y.Z-rc1 or X.Y.Z".colorize(:red)
    exit 1
  end

  version
end

def skip?(repo)
  ENV[repo.upcase] == 'false'
end

desc "Create release"
task :release, [:version] do |t, args|
  version = get_version(args)

  if skip?('ce')
    puts 'Skipping release for CE'.colorize(:red)
  else
    puts "CE release".colorize(:blue)
    Release.new(version, Remotes.ce_remotes).execute
  end

  if skip?('ee')
    puts 'Skipping release for EE'.colorize(:red)
  else
    puts "EE release".colorize(:blue)
    Release.new(version + '-ee', Remotes.ee_remotes).execute
  end
end

desc "Sync master branch in remotes"
task :sync do
  if skip?('ce')
    puts 'Skipping sync for CE'.colorize(:yellow)
  else
    Sync.new(Remotes.ce_remotes).execute
  end

  if skip?('ee')
    puts 'Skipping sync for EE'.colorize(:yellow)
  else
    Sync.new(Remotes.ee_remotes).execute
  end

  if skip?('og')
    puts 'Skipping sync for Omnibus Gitlab'.colorize(:yellow)
  else
    Sync.new(Remotes.omnibus_gitlab_remotes).execute
  end
end

def create_or_show_issue(issue)
  if issue.exists?
    puts "--> Issue \"#{issue.title}\" already exists.".red
    puts "    #{issue.url}"
    exit 1
  else
    issue.create
    puts "--> Issue \"#{issue.title}\" created.".green
    puts "    #{issue.url}"
  end
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
