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
    version = get_version(args).to_ce
    target = ReleaseTools::PreparationMergeRequest.new(version: version)
    $stdout.puts "--> Picking for #{version}..."
    results = ReleaseTools::CherryPick::Service
      .new(ReleaseTools::Project::GitlabCe, version, target)
      .execute

    results.each do |result|
      $stdout.puts cherry_pick_result(result).indent(4)
    end

    # EE
    version = version.to_ee
    target = ReleaseTools::PreparationMergeRequest.new(version: version)
    $stdout.puts "--> Picking for #{version}..."
    results = ReleaseTools::CherryPick::Service
      .new(ReleaseTools::Project::GitlabEe, version, target)
      .execute

    results.each do |result|
      $stdout.puts cherry_pick_result(result).indent(4)
    end
  end

  desc 'Prepare for a new release'
  task :prepare, [:version] do |task, args|
    version = get_version(args)

    Rake::Task['release:issue'].execute(version: version)

    if version.monthly?
      service = ReleaseTools::Services::MonthlyPreparationService.new(version)

      service.create_label
      service.create_stable_branches

      # Recurse so that RC1 gets prep MRs too
      task.execute(version: version.to_rc(1))
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
  end

  desc 'Tag a new release'
  task :tag, [:version] do |_t, args|
    version = get_version(args)

    if skip?('ee')
      $stdout.puts 'Skipping release for EE'.colorize(:red)
    else
      ee_version = version.to_ee

      $stdout.puts 'EE release'.colorize(:blue)
      ReleaseTools::Release::GitlabEeRelease.new(ee_version).execute
      ReleaseTools::Slack::TagNotification.release(ee_version) unless dry_run?
    end

    if skip?('ce')
      $stdout.puts 'Skipping release for CE'.colorize(:red)
    else
      ce_version = version.to_ce

      $stdout.puts 'CE release'.colorize(:blue)
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
end
