namespace :release do
  desc 'Create a release task issue'
  task :issue, [:version] do |_t, args|
    version = get_version(args)

    if version.monthly?
      issue = ReleaseTools::MonthlyIssue.new(version: version)
    else
      issue = ReleaseTools::PatchIssue.new(version: version)
    end

    create_or_show_issue(issue)
  end

  desc 'Merges valid merge requests into preparation branches'
  task :merge, [:version] do |_t, args|
    ee_version = get_version(args).to_ee
    ee_target = ReleaseTools::PreparationMergeRequest.new(version: ee_version)

    ReleaseTools.logger.info(
      'Picking into preparation merge requests',
      version: ee_version,
      target: ee_target.branch_name
    )

    ReleaseTools::CherryPick::Service
      .new(ReleaseTools::Project::GitlabEe, ee_version, ee_target)
      .execute
  end

  desc 'Prepare for a new release'
  task :prepare, [:version] do |_t, args|
    version = get_version(args)

    Rake::Task['release:issue'].execute(version: version)

    if version.monthly?
      service = ReleaseTools::Services::MonthlyPreparationService.new(version)

      service.create_label
    else
      version = version.to_ee
      merge_request = ReleaseTools::PreparationMergeRequest.new(version: version)
      merge_request.create_branch!
      create_or_show_merge_request(merge_request)
    end
  end

  desc 'Create a QA issue'
  task :qa, [:from, :to] do |_t, args|
    version = get_version(version: args[:to].sub(/\Av/, ''))

    issue = ReleaseTools::Qa::Services::BuildQaIssueService.new(
      version: version,
      from: args[:from],
      to: args[:to],
      issue_project: ReleaseTools::Qa::ISSUE_PROJECT,
      projects: ReleaseTools::Qa::PROJECTS
    ).execute

    create_or_show_issue(issue)

    if ENV['RELEASE_ENVIRONMENT'] && issue.status == :exists
      issue.add_comment(<<~MSG)
        :robot: The changes listed in this issue have been deployed
        to `#{ENV['RELEASE_ENVIRONMENT']}`.
      MSG
    end
  end

  desc 'Create stable branches for a new release'
  task :stable_branch, [:version, :source] do |_t, args|
    version = get_version(args)
    return unless version.monthly?

    service = ReleaseTools::Services::MonthlyPreparationService.new(version)
    service.create_stable_branches(source)
  end

  desc 'Records the merge requests that have been deployed'
  task :record_deploy, [:from, :to] do |_, args|
    version = get_version(version: args[:to].sub(/\Av/, ''))

    ReleaseTools::AutoDeploy::MergeRequestNotifier
      .new(from: args[:from], to: args[:to], version: version)
      .notify_all
  end

  desc "Check a release's build status"
  task :status, [:version] do |t, args|
    version = get_version(args)

    status = ReleaseTools::BranchStatus.for([version])

    status.each_pair do |project, results|
      results.each do |result|
        ReleaseTools.logger.tagged(t.name) do
          ReleaseTools.logger.info(project, result.to_h)
        end
      end
    end

    ReleaseTools::Slack::ChatopsNotification.branch_status(status)
  end

  desc 'Tag a new release'
  task :tag, [:version] do |_t, args|
    version = get_version(args)

    if skip?('ce')
      ReleaseTools.logger.warn('Skipping release for CE')
    else
      ce_version = version.to_ce

      ReleaseTools.logger.info('Starting CE release')
      ReleaseTools::Release::GitlabCeRelease.new(ce_version).execute
      ReleaseTools::Slack::TagNotification.release(ce_version) unless dry_run?
    end

    if skip?('ee')
      ReleaseTools.logger.warn('Skipping release for EE')
    else
      ee_version = version.to_ee

      ReleaseTools.logger.info('Starting EE release')
      ReleaseTools::Release::GitlabEeRelease.new(ee_version).execute
      ReleaseTools::Slack::TagNotification.release(ee_version) unless dry_run?
    end
  end

  namespace :gitaly do
    desc 'Tag a new release'
    task :tag, [:version] do |_, args|
      version = get_version(args)

      ReleaseTools::Release::GitalyRelease.new(version).execute
      ReleaseTools::Slack::TagNotification.release(version) unless dry_run?
    end
  end
end
