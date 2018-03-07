require_relative 'init'
require_relative 'lib/support/tasks_helper'
require_relative 'lib/local_repository'

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
    ee_version = version.to_ee

    $stdout.puts 'EE release'.colorize(:blue)
    Release::GitlabEeRelease.new(ee_version, security: security_release?).execute
    Slack::TagNotification.release(ee_version) unless dry_run?
  end

  if skip?('ce')
    $stdout.puts 'Skipping release for CE'.colorize(:red)
  else
    ce_version = version.to_ce

    $stdout.puts 'CE release'.colorize(:blue)
    Release::GitlabCeRelease.new(ce_version, security: security_release?).execute
    Slack::TagNotification.release(ce_version) unless dry_run?
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

  Release::OmnibusGitlabRelease.new(version, security: true).promote_security_release
end

desc "Sync master branch in remotes"
task :sync do
  if skip?('ee')
    $stdout.puts 'Skipping sync for EE'.colorize(:yellow)
  else
    Sync.new(Project::GitlabEe.remotes).execute
  end

  if skip?('ce')
    $stdout.puts 'Skipping sync for CE'.colorize(:yellow)
  else
    Sync.new(Project::GitlabCe.remotes).execute
  end

  if skip?('og')
    $stdout.puts 'Skipping sync for Omnibus Gitlab'.colorize(:yellow)
  else
    Sync.new(Project::OmnibusGitlab.remotes).execute
  end
end

desc "Create the monthly release issue"
task :monthly_issue, [:version] do |_t, args|
  version = get_version(args)
  issue = MonthlyIssue.new(version: version)

  create_or_show_issue(issue)
end

desc "Create a patch issue"
task :patch_issue, [:version] do |_t, args|
  version = get_version(args)
  issue = PatchIssue.new(version: version)

  create_or_show_issue(issue)
end

desc "Create preparation merge requests in CE and EE for a patch release"
task :patch_merge_request, [:version] do |_t, args|
  # CE
  version = get_version(args).to_ce
  merge_request = PreparationMergeRequest.new(version: version)
  merge_request.create_branch!
  create_or_show_merge_request(merge_request)

  # EE
  version = version.to_ee
  merge_request = PreparationMergeRequest.new(version: version)
  merge_request.create_branch!
  create_or_show_merge_request(merge_request)
end

desc "Create a security patch issue"
task :security_patch_issue, [:version] do |_t, args|
  version = get_version(args)
  issue = SecurityPatchIssue.new(version: version)

  create_or_show_issue(issue)
end

desc "Create a CE upstream merge request on EE"
task :upstream_merge do |task|
  moved_to_bin_message(task.name)
end
