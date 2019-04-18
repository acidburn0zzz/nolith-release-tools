# frozen_string_literal: true

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

    auto_deploy_branch = ENV.fetch('AUTO_DEPLOY_BRANCH') do |name|
      abort("`#{name}` must be set for this rake task".colorize(:red))
    end

    version = auto_deploy_branch.sub(/\A(\d+)-(\d+)-auto-deploy.*/, '\1.\2')
    version = ReleaseTools::Version.new(version).to_ee

    target_branch = ReleaseTools::AutoDeployBranch.new(version, auto_deploy_branch)

    $stdout.puts "--> Picking for #{version}..."
    ee_results = ReleaseTools::CherryPick::Service
      .new(ReleaseTools::Project::GitlabEe, version, target_branch)
      .execute

    ee_results.each do |result|
      $stdout.puts "    #{icon.call(result)} #{result.url}"
    end

    version = version.to_ce
    $stdout.puts "--> Picking for #{version}..."
    ce_results = ReleaseTools::CherryPick::Service
      .new(ReleaseTools::Project::GitlabCe, version, target_branch)
      .execute

    ce_results.each do |result|
      $stdout.puts "    #{icon.call(result)} #{result.url}"
    end

    if ee_results.none?(&:success?) && ce_results.none?(&:success?)
      raise "Nothing was picked, bailing..."
    end

    ReleaseTools::GitlabOpsClient.run_trigger(
      ReleaseTools::Project::MergeTrain,
      ENV.fetch['MERGE_TRAIN_TRIGGER_TOKEN'],
      'master',
      {
        CE_BRANCH: auto_deploy_branch,
        EE_BRANCH: auto_deploy_branch
      }
    ) unless ReleaseTools::SharedStatus.dry_run?
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
