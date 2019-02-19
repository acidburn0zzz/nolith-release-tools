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

desc "Tag a new GitLab release"
task :tag, [:version] do |_t, args|
  version = get_version(args)

  if SharedStatus.security_release?
    $stdout.puts "Security Release - using dev.gitlab.org only!".colorize(:red)
    $stdout.puts
  end

  if skip?('ee')
    $stdout.puts 'Skipping release for EE'.colorize(:red)
  else
    ee_version = version.to_ee

    $stdout.puts 'EE release'.colorize(:blue)
    Release::GitlabEeRelease.new(ee_version).execute
    Slack::TagNotification.release(ee_version) unless dry_run?
  end

  if skip?('ce')
    $stdout.puts 'Skipping release for CE'.colorize(:red)
  else
    ce_version = version.to_ce

    $stdout.puts 'CE release'.colorize(:blue)
    Release::GitlabCeRelease.new(ce_version).execute
    Slack::TagNotification.release(ce_version) unless dry_run?
  end
end

desc "Tag a new GitLab security release"
task :tag_security, [:version] do |_t, args|
  ENV['SECURITY'] = 'true'
  Rake::Task[:tag].invoke(args[:version])
end

# For legacy reasons, alias `[security_]release` to `tag[_security]`
task :release, [:version] => :tag
task :security_release, [:version] => :tag_security

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

desc "Create a QA issue"
task :qa_issue, [:from, :to, :version] do |_t, args|
  # Attempt to infer the version from the `to` ref
  version = get_version(args.with_defaults(version: args[:to].sub(/\Av/, '')))

  issue = Qa::Services::BuildQaIssueService.new(
    version: version,
    from: args[:from],
    to: args[:to],
    issue_project: Qa::ISSUE_PROJECT,
    projects: Qa::PROJECTS
  ).execute

  create_or_show_issue(issue)
end

desc "Create a QA issue for a security release"
task :security_qa_issue, [:from, :to, :version] do |_t, args|
  ENV['SECURITY'] = 'true'
  Rake::Task[:qa_issue].invoke(args[:from], args[:to], args[:version])
end

desc 'Closes expired QA issues'
task :close_expired_qa_issues do
  Qa::IssueCloser.new.execute
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

desc "Cherry-pick merge requests into preparation branches"
task :cherry_pick, [:version] do |_t, args|
  icon = -> (result) { result.success? ? "✓" : "✗" }

  # CE
  version = get_version(args).to_ce
  $stdout.puts "--> Picking for #{version}..."
  results = CherryPick::Service.new(Project::GitlabCe, version).execute
  results.each do |result|
    $stdout.puts "    #{icon.call(result)} #{result.url}"
  end

  # EE
  version = version.to_ee
  $stdout.puts "--> Picking for #{version}..."
  results = CherryPick::Service.new(Project::GitlabEe, version).execute
  results.each do |result|
    $stdout.puts "    #{icon.call(result)} #{result.url}"
  end
end

task :security_cherry_pick, [:version] do |_t, args|
  ENV['SECURITY'] = 'true'
  Rake::Task[:cherry_pick].invoke(args[:version])
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
      Slack::UpstreamMergeNotification.new_merge_request(upstream_mr) unless dry_run?
    else
      $stdout.puts <<~SUCCESS_MESSAGE.colorize(:yellow)
        --> Merge request "#{upstream_mr.title}" not created.
      SUCCESS_MESSAGE
      Slack::UpstreamMergeNotification.missing_merge_request unless dry_run?
    end
  elsif result.payload[:in_progress_mr]
    in_progress_mr = result.payload[:in_progress_mr]
    $stdout.puts <<~ERROR_MESSAGE.colorize(:red)
    --> An upstream merge request already exists.
        #{in_progress_mr.url}
    ERROR_MESSAGE
    Slack::UpstreamMergeNotification.existing_merge_request(in_progress_mr) unless dry_run?
  elsif result.payload[:already_up_to_date]
    $stdout.puts <<~ERROR_MESSAGE.colorize(:green)
    --> EE is already up-to-date with CE. No merge request was created.
    ERROR_MESSAGE
    Slack::UpstreamMergeNotification.downstream_is_up_to_date unless dry_run?
  end
end

namespace :release_managers do
  desc "Verify release manager authorization"
  task :auth, [:username] do |_t, args|
    unless args[:username].present?
      abort "You must provide a username to verify!"
    end

    unless ReleaseManagers::Definitions.allowed?(args[:username])
      abort "#{args[:username]} is not an authorized release manager!"
    end
  end

  desc "Sync Release Manager membership"
  task :sync do
    result = ReleaseManagers::Definitions.sync!

    unless result.success?
      $stdout.puts result.formatted_error_message
      exit 1
    end
  end
end

namespace :helm do
  desc "Create a chart release by passing in chart_version,gitlab_version"
  task :tag_chart, [:version, :gitlab_version] do |_t, args|
    version = HelmChartVersion.new(args[:version]) if args[:version] && !args[:version].empty?
    gitlab_version = HelmGitlabVersion.new(args[:gitlab_version]) if args[:gitlab_version] && !args[:gitlab_version].empty?

    # At least one of the versions must be provided in order to tag
    if (!version && !gitlab_version) || (version && !version.valid?) || (gitlab_version && !gitlab_version.valid?)
      $stdout.puts "Version number must be in the following format: X.Y.Z".colorize(:red)
      exit 1
    end

    $stdout.puts 'Chart release'.colorize(:blue)
    Release::HelmGitlabRelease.new(version, gitlab_version).execute
  end
end

desc "Publish packages for a specified version"
task :publish, [:version] do |_t, args|
  version = get_version(args)

  Packages::PublishService
    .new(version)
    .execute
end

desc 'Announce the feature freeze on Slack'
task :freeze do
  require 'httparty'
  require 'json'

  webhook_url = ENV.fetch('FEATURE_FREEZE_WEBHOOK_URL')

  # We don't wrap this string so the sentences appear on a single line in Slack,
  # instead of being spread across separate lines.
  message = <<~MESSAGE.strip
    <!channel>

    The feature freeze is now active. This means that no new features will be merged into the stable branches for this month's release.

    For more information, refer to <https://gitlab.com/gitlab-org/gitlab-ce/blob/master/PROCESS.md#after-the-7th|"After the 7th">.
  MESSAGE

  HTTParty.post(webhook_url, body: { payload: JSON.dump(text: message) })
end
