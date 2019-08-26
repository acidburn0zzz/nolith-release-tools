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
    # CE
    ce_version = get_version(args).to_ce
    ce_target = ReleaseTools::PreparationMergeRequest.new(version: ce_version)

    $stdout.puts "--> Picking for #{ce_version}..."
    ce_results = ReleaseTools::CherryPick::Service
      .new(ReleaseTools::Project::GitlabCe, ce_version, ce_target)
      .execute

    ce_results.each do |result|
      $stdout.puts cherry_pick_result(result).indent(4)
    end

    # EE
    ee_version = ce_version.to_ee
    ee_target = ReleaseTools::PreparationMergeRequest.new(version: ee_version)

    $stdout.puts "--> Picking for #{ee_version}..."
    ee_results = ReleaseTools::CherryPick::Service
      .new(ReleaseTools::Project::GitlabEe, ee_version, ee_target)
      .execute

    ee_results.each do |result|
      $stdout.puts cherry_pick_result(result).indent(4)
    end

    exit if ReleaseTools::SharedStatus.dry_run?

    # If we picked anything in CE, we need to merge into EE via MergeTrain
    if ce_results.any?(&:success?)
      $stdout.puts "--> Triggering merge train for `#{ce_target.source_branch}`"

      pipeline = ReleaseTools::GitlabOpsClient.run_trigger(
        ReleaseTools::Project::MergeTrain,
        ENV.fetch('MERGE_TRAIN_TRIGGER_TOKEN'),
        'master',
        SOURCE_BRANCH: ce_target.source_branch,
        TARGET_BRANCH: ee_target.source_branch,
        MERGE_MANUAL: '1'
      )

      $stdout.puts pipeline.web_url.indent(4)
    end
  end

  desc 'Prepare for a new release'
  task :prepare, [:version] do |_t, args|
    version = get_version(args)

    Rake::Task['release:issue'].execute(version: version)

    if version.monthly?
      service = ReleaseTools::Services::MonthlyPreparationService.new(version)

      service.create_label
    else
      # Create preparation MR for CE
      version = version.to_ce
      merge_request = ReleaseTools::PreparationMergeRequest.new(version: version)
      merge_request.create_branch!
      create_or_show_merge_request(merge_request)

      # Create preparation MR for EE
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

  desc "Check a release's build status"
  task :status, [:version] do |_t, args|
    version = get_version(args)

    status = ReleaseTools::BranchStatus.for([version])

    status.each_pair do |project, results|
      results.each do |result|
        ReleaseTools.logger.info(project, result.to_h)
      end
    end

    ReleaseTools::Slack::ChatopsNotification.branch_status(status)
  end

  desc 'Tag a new release'
  task :tag, [:version] do |_t, args|
    version = get_version(args)

    if skip?('ce')
      $stdout.puts 'Skipping release for CE'.colorize(:red)
    else
      ce_version = version.to_ce

      $stdout.puts 'CE release'.colorize(:blue)
      ReleaseTools::Release::GitlabCeRelease.new(ce_version).execute
      ReleaseTools::Slack::TagNotification.release(ce_version) unless dry_run?
    end

    if skip?('ee')
      $stdout.puts 'Skipping release for EE'.colorize(:red)
    else
      ee_version = version.to_ee

      $stdout.puts 'EE release'.colorize(:blue)
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
