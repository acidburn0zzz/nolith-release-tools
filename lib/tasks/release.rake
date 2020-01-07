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
    pick = lambda do |project, version|
      target = ReleaseTools::PreparationMergeRequest
        .new(project: project, version: version)

      ReleaseTools.logger.info(
        'Picking into preparation merge requests',
        project: project,
        version: version,
        target: target.branch_name
      )

      ReleaseTools::CherryPick::Service
        .new(project, version, target)
        .execute
    end

    version = get_version(args).to_ee

    pick[ReleaseTools::Project::GitlabEe, version]
    pick[ReleaseTools::Project::OmnibusGitlab, version.to_ce]
  end

  desc 'Prepare for a new release'
  task :prepare, [:version] do |_t, args|
    version = get_version(args)

    Rake::Task['release:issue'].execute(version: version)

    if version.monthly?
      service = ReleaseTools::Services::MonthlyPreparationService.new(version)

      service.create_label
    else
      # GitLab EE
      version = version.to_ee
      merge_request = ReleaseTools::PreparationMergeRequest
        .new(project: ReleaseTools::Project::GitlabEe, version: version)
      merge_request.create_branch!
      create_or_show_merge_request(merge_request)

      # Omnibus
      version = version.to_ce
      merge_request = ReleaseTools::PreparationMergeRequest
        .new(project: ReleaseTools::Project::OmnibusGitlab, version: version)
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

    if version.monthly?
      service = ReleaseTools::Services::MonthlyPreparationService.new(version)
      service.create_stable_branches(args[:source])
    end
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

    if skip?('ee')
      ReleaseTools.logger.warn('Skipping release for EE')
    else
      ee_version = version.to_ee

      ReleaseTools.logger.info('Starting EE release')
      ReleaseTools::Release::GitlabEeRelease.new(ee_version).execute
      ReleaseTools::Slack::TagNotification.release(ee_version) unless dry_run?
    end

    if skip?('ce')
      ReleaseTools.logger.warn('Skipping release for CE')
    else
      ce_version = version.to_ce

      ReleaseTools.logger.info('Starting CE release')
      ReleaseTools::Release::GitlabCeRelease.new(ce_version).execute
      ReleaseTools::Slack::TagNotification.release(ce_version) unless dry_run?
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

  namespace :helm do
    desc 'Tag a new release'
    task :tag, [:charts_version, :gitlab_version] do |_t, args|
      charts_version = ReleaseTools::HelmChartVersion.new(args[:charts_version]) if args[:charts_version] && !args[:charts_version].empty?
      gitlab_version = ReleaseTools::HelmGitlabVersion.new(args[:gitlab_version]) if args[:gitlab_version] && !args[:gitlab_version].empty?

      # At least one of the versions must be provided in order to tag
      if (!charts_version && !gitlab_version) || (charts_version && !charts_version.valid?) || (gitlab_version && !gitlab_version.valid?)
        ReleaseTools.logger.warn('Version number must be in the following format: X.Y.Z')
        exit 1
      end

      ReleaseTools.logger.info(
        'Chart release',
        charts_version: charts_version,
        gitlab_version: gitlab_version
      )
      ReleaseTools::Release::HelmGitlabRelease.new(charts_version, gitlab_version).execute
    end
  end
end
