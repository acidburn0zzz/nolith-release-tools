require 'colorize'

require_relative 'lib/version'
require_relative 'lib/monthly_issue'
require_relative 'lib/patch_issue'
require_relative 'lib/regression_issue'
require_relative 'lib/security_patch_issue'
require_relative 'lib/release/gitlab_ce_release'
require_relative 'lib/release/gitlab_ee_release'
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
    $stdout.puts "Version number must be in the following format: X.Y.Z-rc1 or X.Y.Z".colorize(:red)
    exit 1
  end

  version
end

def skip?(repo)
  ENV[repo.upcase] == 'false'
end

def security_release?
  ENV['SECURITY'] == 'true'
end

desc "Create release"
task :release, [:version] do |_t, args|
  version = get_version(args)

  if skip?('ee')
    $stdout.puts 'Skipping release for EE'.colorize(:red)
  else
    $stdout.puts 'EE release'.colorize(:blue)
    Release::GitlabEeRelease.new("#{version}-ee", security: security_release?).execute
  end

  if skip?('ce')
    $stdout.puts 'Skipping release for CE'.colorize(:red)
  else
    $stdout.puts 'CE release'.colorize(:blue)
    Release::GitlabCeRelease.new(version, security: security_release?).execute
  end
end

desc "Sync master branch in remotes"
task :sync do
  if skip?('ee')
    $stdout.puts 'Skipping sync for EE'.colorize(:yellow)
  else
    Sync.new(Remotes.ee_remotes).execute
  end

  if skip?('ce')
    $stdout.puts 'Skipping sync for CE'.colorize(:yellow)
  else
    Sync.new(Remotes.ce_remotes).execute
  end


  if skip?('og')
    $stdout.puts 'Skipping sync for Omnibus Gitlab'.colorize(:yellow)
  else
    Sync.new(Remotes.omnibus_gitlab_remotes).execute
  end
end

def create_or_show_issue(issue)
  if issue.exists?
    $stdout.puts "--> Issue \"#{issue.title}\" already exists.".red
    $stdout.puts "    #{issue.url}"
    exit 1
  else
    issue.create
    $stdout.puts "--> Issue \"#{issue.title}\" created.".green
    $stdout.puts "    #{issue.url}"
  end
end

desc "Create the monthly release issue"
task :monthly_issue, [:version] do |_t, args|
  version = get_version(args)
  issue = MonthlyIssue.new(version)

  create_or_show_issue(issue)
end

desc "Create the regression tracking issue"
task :regression_issue, [:version] do |_t, args|
  version = get_version(args)
  issue = RegressionIssue.new(version)

  create_or_show_issue(issue)
end

desc "Create a patch issue"
task :patch_issue, [:version] do |_t, args|
  version = get_version(args)
  issue = PatchIssue.new(version)

  create_or_show_issue(issue)
end

desc "Create a security patch issue"
task :security_patch_issue, [:version] do |_t, args|
  version = get_version(args)
  issue = SecurityPatchIssue.new(version)

  create_or_show_issue(issue)
end
