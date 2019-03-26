namespace :security do
  # Undocumented; should be a pre-requisite for every task in this namespace!
  task :force_security do
    ENV['SECURITY'] = 'true'
  end

  desc 'Create a security release task issue'
  task :issue, [:version] => :force_security do |_t, args|
    version = get_version(args)

    issue = ReleaseTools::SecurityPatchIssue.new(version: version)

    create_or_show_issue(issue)
  end

  desc 'Merges valid security merge requests'
  task :merge, [:merge_master] => :force_security do |_t, args|
    merge_master =
      if args[:merge_master] && !args[:merge_master].empty?
        true
      else
        false
      end

    ReleaseTools::Security::MergeRequestsMerger
      .new(merge_master: merge_master)
      .execute
  end

  desc 'Prepare for a new security release'
  task :prepare, [:version] => :force_security do |_t, _args|
    issue_task = Rake::Task['security:issue']
    service = ReleaseTools::Services::SecurityPreparationService.new

    service.next_versions.each do |version|
      issue_task.execute(version: version)
    end
  end

  desc 'Create a security QA issue'
  task :qa, [:from, :to] => :force_security do |_t, args|
    Rake::Task['release:qa'].invoke(*args)
  end

  desc 'Tag a new security release'
  task :tag, [:version] => :force_security do |_t, args|
    $stdout
      .puts "Security Release - using security repository only!\n"
      .colorize(:red)

    Rake::Task['release:tag'].invoke(*args)
  end

  # Undocumented; executed via CI schedule
  task validate: :force_security do
    ReleaseTools::Security::MergeRequestsValidator
      .new
      .execute
  end
end
