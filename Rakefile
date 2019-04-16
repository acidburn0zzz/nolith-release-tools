# frozen_string_literal: true
require 'pry'

require_relative 'lib/release_tools'
require_relative 'lib/release_tools/support/tasks_helper'

Dir.glob('lib/tasks/*.rake').each { |task| import(task) }

namespace :auto_deploy do
  desc "Prepare for auto-deploy by creating branches from the latest green commit on gitlab-ee and omnibus-gitlab"
  task :prepare do
    ReleaseTools::Services::AutoDeployBranchService
      .new(ReleaseTools::AutoDeploy::Naming.branch)
      .create_branches!
  end

  desc 'Pick commits into the auto deploy branches'
  task :pick do
    icon = ->(result) { result.success? ? "✓" : "✗" }

    auto_deploy_branch = ENV['AUTO_DEPLOY_BRANCH']
    abort('AUTO_DEPLOY_BRANCH must be set for this rake task'.colorize(:red)) unless auto_deploy_branch
    puts "We'll pick into #{auto_deploy_branch}"

    scrub_version = auto_deploy_branch.match(/^(\d+-\d+)-auto-deploy.*/)[1].tr('-', '.')
    version = ReleaseTools::Version.new(scrub_version).to_ee
    $stdout.puts "--> Picking for #{version}..."

    $stdout.puts "Cherry-picking for EE..."
    results = ReleaseTools::CherryPick::Service
      .new(ReleaseTools::Project::GitlabEe, version, auto_deploy_branch)
      .execute

    successful_picks = 0
    results.each do |result|
      successful_picks += 1 if result.success?
      $stdout.puts "    #{icon.call(result)} #{result.url}"
    end

    $stdout.puts "Cherry-picking for CE..."
    version = ReleaseTools::Version.new(scrub_version).to_ce
    results = ReleaseTools::CherryPick::Service
      .new(ReleaseTools::Project::GitlabCe, version, auto_deploy_branch)
      .execute

    results.each do |result|
      successful_picks += 1 if result.success?
      $stdout.puts "    #{icon.call(result)} #{result.url}"
    end

    raise "Nothing was picked, bailing..." if successful_picks == 0

    conflicts = ReleaseTools::UpstreamMerge.new(
      origin: ReleaseTools::Project::GitlabEe.remotes[:gitlab],
      upstream: ReleaseTools::Project::GitlabCe.remotes[:gitlab],
      source_branch: auto_deploy_branch,
      target_branch: auto_deploy_branch
    ).execute!

    unless conflicts.nil?
      raise "Conflicts in CE to EE merge."
    end
  end
end

desc "Sync master branch in remotes"
task :sync do
  if skip?('ee')
    $stdout.puts 'Skipping sync for EE'.colorize(:yellow)
  else
    ReleaseTools::Sync.new(ReleaseTools::Project::GitlabEe.remotes).execute
  end

  if skip?('ce')
    $stdout.puts 'Skipping sync for CE'.colorize(:yellow)
  else
    ReleaseTools::Sync.new(ReleaseTools::Project::GitlabCe.remotes).execute
  end

  if skip?('og')
    $stdout.puts 'Skipping sync for Omnibus Gitlab'.colorize(:yellow)
  else
    ReleaseTools::Sync.new(ReleaseTools::Project::OmnibusGitlab.remotes).execute
  end
end

# Undocumented; executed via CI schedule
task :close_expired_qa_issues do
  ReleaseTools::Qa::IssueCloser.new.execute
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

  # Tag the Helm chart
  begin
    Rake::Task['helm:tag_chart'].invoke(nil, version.to_ce)
  rescue StandardError => ex
    Raven.capture_exception(ex)
  end
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
