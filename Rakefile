# frozen_string_literal: true

require_relative 'lib/release_tools'
require_relative 'lib/release_tools/support/tasks_helper'

Dir.glob('lib/tasks/*.rake').each { |task| import(task) }

namespace :auto_deploy do
  desc "Prepare for auto-deploy by creating branches from the latest green commit on gitlab-ee and omnibus-gitlab"
  task :prepare do
    results = ReleaseTools::Services::AutoDeployBranchService
      .new(ReleaseTools::AutoDeploy::Naming.branch)
      .create_branches!

    ReleaseTools::Slack::AutoDeployNotification
      .on_create(results)
  end

  def auto_deploy_pick(project, version)
    $stdout.puts "--> Picking for #{project}@#{version.auto_deploy_branch}"

    results = ReleaseTools::CherryPick::Service
      .new(project, version, version.auto_deploy_branch)
      .execute

    results.each do |result|
      $stdout.puts cherry_pick_result(result).indent(4)
    end
  end

  desc 'Pick commits into the auto deploy branches'
  task :pick do
    auto_deploy_branch = ENV.fetch('AUTO_DEPLOY_BRANCH') do |name|
      abort("`#{name}` must be set for this rake task".colorize(:red))
    end

    version = ReleaseTools::AutoDeploy::Version
      .from_branch(auto_deploy_branch)
      .to_ee

    ee_results = auto_deploy_pick(ReleaseTools::Project::GitlabEe, version)
    ce_results = auto_deploy_pick(ReleaseTools::Project::GitlabCe, version.to_ce)
    _ob_results = auto_deploy_pick(ReleaseTools::Project::OmnibusGitlab, version)

    exit if ReleaseTools::SharedStatus.dry_run?

    if ee_results.any?(&:success?) || ce_results.any?(&:success?)
      $stdout.puts "--> Triggering merge train for `#{auto_deploy_branch}`"

      pipeline = ReleaseTools::GitlabOpsClient.run_trigger(
        ReleaseTools::Project::MergeTrain,
        ENV.fetch('MERGE_TRAIN_TRIGGER_TOKEN'),
        'master',
        {
          CE_BRANCH: auto_deploy_branch,
          EE_BRANCH: auto_deploy_branch,
          MERGE_MANUAL: '1'
        }
      )

      $stdout.puts pipeline.web_url.indent(4)
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

  ReleaseTools::Services::OmnibusPublishService
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
  require 'http'
  require 'json'

  webhook_url = ENV.fetch('FEATURE_FREEZE_WEBHOOK_URL')

  # We don't wrap this string so the sentences appear on a single line in Slack,
  # instead of being spread across separate lines.
  message = <<~MESSAGE.strip
    <!channel>

    The feature freeze is now active. This means that no new features will be merged into the stable branches for this month's release.

    For more information, refer to <https://gitlab.com/gitlab-org/gitlab-ce/blob/master/PROCESS.md#after-the-7th|"After the 7th">.
  MESSAGE

  HTTP.post(webhook_url, json: { text: message })
end
