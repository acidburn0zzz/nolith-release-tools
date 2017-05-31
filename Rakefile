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

unless Rake.application.top_level_tasks.include?('default') || LocalRepository.ready?
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

desc "Create the regression tracking issue"
task :regression_issue, [:version] do |_t, args|
  version = get_version(args)
  issue = RegressionIssue.new(version: version)

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

  merge_request = PatchPreparationMergeRequest.new(version: version)
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
  open_merge_requests = UpstreamMergeRequest.open_mrs

  if open_merge_requests.any?
    $stdout.puts "--> An upstream merge request already exists.".red
    $stdout.puts "    #{open_merge_requests.first.url}"
    exit 1
  end

  merge_request = UpstreamMergeRequest.new
  merge = UpstreamMerge.new(
    origin: Project::GitlabEe.remotes[:gitlab],
    upstream: Project::GitlabCe.remotes[:gitlab],
    merge_branch: merge_request.source_branch)

  conflicts_data = merge.execute
  merge_request.description(conflicts_data, mention_people: mention?)

  $stdout.puts "\nFollowing is the decription of the MR that will be created:\n"
  $stdout.puts "```\n#{merge_request.description}\n```"

  mr_created = !dry_run? && merge_request.create

  $stdout.puts "--> Merge request \"#{merge_request.title}\" #{'not ' unless mr_created}created.".green
  $stdout.puts "    #{merge_request.url}"
end
