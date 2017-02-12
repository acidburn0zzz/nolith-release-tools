require_relative 'init'
require_relative 'lib/support/tasks_helper'

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task default: :spec
rescue LoadError
  # no rspec available
end

desc "Create release"
task :release, [:version] do |_t, args|
  version = get_version(args)

  if security_release?
    $stdout.puts "Security Release - using dev.gitlab.org only!".colorize(:red)
    $stdout.puts
  end

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

desc "Create a security release"
task :security_release, [:version] do |_t, args|
  ENV['SECURITY'] = 'true'
  Rake::Task[:release].invoke(args[:version])
end

desc "Promote security release packages to public"
task :promote_security_release, [:version] do |_t, args|
  ENV['SECURITY'] = 'true'
  version = get_version(args)

  Release::OmnibusGitLabRelease.new(version, security: true).promote_security_release
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

desc "Deploy in interactive mode"
task :deploy, [:version] do |_t, args|
  ENV['TERM'] = 'xterm-256color'
  version = get_version(args)

  # TODO: Figure out why colors do not work unless we spawn a new process.
  spawn("ruby #{Dir.pwd}/lib/gid/app.rb #{version}")

  Process.wait
end
