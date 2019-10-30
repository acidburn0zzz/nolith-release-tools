# frozen_string_literal: true

require_relative 'lib/release_tools'
require_relative 'lib/release_tools/support/tasks_helper'

Dir.glob('lib/tasks/*.rake').each { |task| import(task) }

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

desc "Publish packages, tags, stable branches, and CNG images for a specified version"
task :publish, [:version] do |_t, args|
  version = get_version(args)

  ReleaseTools::Services::OmnibusPublishService
    .new(version)
    .execute

  ReleaseTools::Services::CNGPublishService
    .new(version)
    .execute

  # Ensure any exceptions raised by this new service don't fail the build, since
  # all destructive behaviors are behind feature flags.
  Raven.capture do
    ReleaseTools::Services::SyncRemotesService
      .new(version)
      .execute
  end

  # Tag the Helm chart
  begin
    Rake::Task['release:helm:tag'].invoke(nil, version.to_ce)
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

    For more information, refer to <https://gitlab.com/gitlab-org/gitlab/blob/master/PROCESS.md#after-the-7th|"After the 7th">.
  MESSAGE

  HTTP.post(webhook_url, json: { text: message })
end
