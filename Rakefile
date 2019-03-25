# frozen_string_literal: true

require_relative 'lib/release_tools'
require_relative 'lib/release_tools/support/tasks_helper'

Dir.glob('lib/tasks/*.rake').each { |task| import(task) }

unless ENV['CI'] || Rake.application.top_level_tasks.include?('default') || ReleaseTools::LocalRepository.ready?
  abort('Please use the master branch and make sure you are up to date.'.colorize(:red))
end

def deprecate_as(new_task, old_task, args)
  warn "This task has been deprecated in favor of " \
    "`#{new_task.colorize(:green)}` and will soon be removed."

  Raven.capture_message(
    "Use of deprecated task #{old_task.name}",
    extra: args,
    level: 'info'
  )

  Rake::Task[new_task].invoke(*args)
end

namespace :green_master do
  desc "Trigger a green master build for EE"
  task :ee, [:trigger_build] do |_t, args|
    commit = ReleaseTools::Commits.new(ReleaseTools::Project::GitlabEe).latest_successful

    raise 'No recent master builds have green pipelines' if commit.nil?

    $stdout.puts "Found EE Green Master at #{commit.id}"

    if args.trigger_build
      ReleaseTools::Pipeline.new(
        ReleaseTools::Project::GitlabEe,
        commit.id
      ).trigger
    end
  end

  desc "Trigger a green master build for CE"
  task :ce, [:trigger_build] do |_t, args|
    commit = ReleaseTools::Commits.new(ReleaseTools::Project::GitlabCe).latest_successful

    raise 'No recent master builds have green pipelines' if commit.nil?

    $stdout.puts "Found CE Green Master at #{commit.id}"

    if args.trigger_build
      ReleaseTools::Pipeline.new(
        ReleaseTools::Project::GitlabCe,
        commit.id
      ).trigger
    end
  end

  desc "Trigger a green master build for both CE and EE"
  task :all, [:trigger_build] do |_t, args|
    Rake::Task['green_master:ee'].invoke(args.trigger_build)
    Rake::Task['green_master:ce'].invoke(args.trigger_build)
  end
end

task :tag, [:version] do |t, args|
  deprecate_as 'release:tag', t, args
end

task :tag_security, [:version] do |t, args|
  deprecate_as 'security:tag', t, args
end

desc "Sync master branch in remotes"
task :sync do
  ReleaseTools::Sync
    .new(ReleaseTools::Project::GitlabEe.remotes)
    .execute('rs-test-sync')
end

task :monthly_issue, [:version] do |t, args|
  deprecate_as 'release:issue', t, args
end

task :patch_issue, [:version] do |t, args|
  deprecate_as 'release:issue', t, args
end

task :qa_issue, [:from, :to, :version] do |t, args|
  deprecate_as 'release:qa', t, args
end

task :security_qa_issue, [:from, :to, :version] do |t, args|
  deprecate_as 'security:qa', t, args
end

# Undocumented; executed via CI schedule
task :close_expired_qa_issues do
  ReleaseTools::Qa::IssueCloser.new.execute
end

task :patch_merge_request, [:version] do |t, args|
  deprecate_as 'release:prepare', t, args
end

task :cherry_pick, [:version] do |t, args|
  deprecate_as 'release:merge', t, args
end

task :security_cherry_pick, [:version] do |t, args|
  deprecate_as 'security:merge', t, args
end

task :security_patch_issue, [:version] do |t, args|
  deprecate_as 'security:issue', t, args
end

# Undocumented; executed via CI schedule
task :upstream_merge do
  result = ReleaseTools::Services::UpstreamMergeService
    .new(dry_run: dry_run?, mention_people: !no_mention?, force: force?)
    .perform

  if result.success?
    upstream_mr = result.payload[:upstream_mr]
    if upstream_mr.exists?
      $stdout.puts <<~SUCCESS_MESSAGE.colorize(:green)
        --> Merge request "#{upstream_mr.title}" created.
            #{upstream_mr.url}
      SUCCESS_MESSAGE
      ReleaseTools::Slack::UpstreamMergeNotification.new_merge_request(upstream_mr) unless dry_run?
    else
      $stdout.puts <<~SUCCESS_MESSAGE.colorize(:yellow)
        --> Merge request "#{upstream_mr.title}" not created.
      SUCCESS_MESSAGE
      ReleaseTools::Slack::UpstreamMergeNotification.missing_merge_request unless dry_run?
    end
  elsif result.payload[:in_progress_mr]
    in_progress_mr = result.payload[:in_progress_mr]
    $stdout.puts <<~ERROR_MESSAGE.colorize(:red)
    --> An upstream merge request already exists.
        #{in_progress_mr.url}
    ERROR_MESSAGE
    ReleaseTools::Slack::UpstreamMergeNotification.existing_merge_request(in_progress_mr) unless dry_run?
  elsif result.payload[:already_up_to_date]
    $stdout.puts <<~ERROR_MESSAGE.colorize(:green)
    --> EE is already up-to-date with CE. No merge request was created.
    ERROR_MESSAGE
    ReleaseTools::Slack::UpstreamMergeNotification.downstream_is_up_to_date unless dry_run?
  end
end

namespace :helm do
  desc "Create a chart release by passing in chart_version,gitlab_version"
  task :tag_chart, [:version, :gitlab_version] do |_t, args|
    version = ReleaseTools::HelmChartVersion.new(args[:version]) if args[:version] && !args[:version].empty?
    gitlab_version = ReleaseTools::HelmGitlabVersion.new(args[:gitlab_version]) if args[:gitlab_version] && !args[:gitlab_version].empty?

    # At least one of the versions must be provided in order to tag
    if (!version && !gitlab_version) || (version && !version.valid?) || (gitlab_version && !gitlab_version.valid?)
      $stdout.puts "Version number must be in the following format: X.Y.Z".colorize(:red)
      exit 1
    end

    $stdout.puts 'Chart release'.colorize(:blue)
    ReleaseTools::Release::HelmGitlabRelease.new(version, gitlab_version).execute
  end
end

desc "Publish packages for a specified version"
task :publish, [:version] do |_t, args|
  version = get_version(args)

  ReleaseTools::Packages::PublishService
    .new(version)
    .execute
end

# Undocumented; executed via CI schedule
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
