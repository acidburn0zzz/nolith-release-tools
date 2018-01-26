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

unless ENV['CI'] || Rake.application.top_level_tasks.include?('default') || LocalRepository.ready?
  abort('Please use the master branch and make sure you are up to date.'.colorize(:red))
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

desc "Create merge requests for patch release"
task :patch_merge_request, [:version] do |_t, args|
  version = get_version(args)

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
task :upstream_merge do
  result = Services::UpstreamMergeService
    .new(dry_run: dry_run?, mention_people: !no_mention?, force: force?)
    .perform

  if result.success?
    upstream_mr = result.payload[:upstream_mr]
    if upstream_mr.exists?
      $stdout.puts <<~SUCCESS_MESSAGE.colorize(:green)
        --> Merge request "#{upstream_mr.title}" created.
            #{upstream_mr.url}
      SUCCESS_MESSAGE
      SlackWebhook.new_merge_request(upstream_mr) unless dry_run?
    else
      $stdout.puts <<~SUCCESS_MESSAGE.colorize(:yellow)
        --> Merge request "#{upstream_mr.title}" not created.
      SUCCESS_MESSAGE
      SlackWebhook.missing_merge_request unless dry_run?
    end
  elsif result.payload[:in_progress_mr]
    in_progress_mr = result.payload[:in_progress_mr]
    $stdout.puts <<~ERROR_MESSAGE.colorize(:red)
    --> An upstream merge request already exists.
        #{in_progress_mr.url}
    ERROR_MESSAGE
    SlackWebhook.existing_merge_request(in_progress_mr) unless dry_run?
  elsif result.payload[:already_up_to_date]
    $stdout.puts <<~ERROR_MESSAGE.colorize(:green)
    --> EE is already up-to-date with CE. No merge request was created.
    ERROR_MESSAGE
    SlackWebhook.downstream_is_up_to_date unless dry_run?
  end
end
