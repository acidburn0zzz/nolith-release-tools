# frozen_string_literal: true

namespace :prepare do
  desc 'Prepare for a new monthly release'
  task :monthly, [:version] do |_t, args|
    version = get_version(args)

    # Create the `Pick into X.Y` label
    ignoring_duplicates do
      $stdout.puts "Creating `#{ReleaseTools::PickIntoLabel.for(version)}` label"
      ReleaseTools::PickIntoLabel.create(version) unless dry_run?
    end

    # Create the stable branches
    ce_branch = version.stable_branch(ee: false)
    ee_branch = version.stable_branch(ee: true)

    create_stable_branch(ReleaseTools::Project::GitlabEe, ee_branch)
    create_stable_branch(ReleaseTools::Project::GitlabCe, ce_branch)
    create_stable_branch(ReleaseTools::Project::OmnibusGitlab, ee_branch)
    create_stable_branch(ReleaseTools::Project::OmnibusGitlab, ce_branch)
  end

  desc 'Prepare the next security release'
  task :security_release do
    issue_task = Rake::Task['security_patch_issue']
    service = ReleaseTools::Services::SecurityPreparationService.new

    service.next_versions.each do |version|
      issue_task.execute(version: version)
    end
  end

  def ignoring_duplicates(&block)
    yield
  rescue Gitlab::Error::Conflict, Gitlab::Error::BadRequest => ex
    if ex.message.match?('already exists')
      # no-op for idempotency
    else
      raise
    end
  end

  # Create a branch off of `master` in the specified project
  def create_stable_branch(project, branch)
    $stdout.puts "Creating `#{branch}` on `#{project.path}`"

    return if dry_run?

    ignoring_duplicates do
      ReleaseTools::GitlabClient.create_branch(branch, 'master', project)
    end
  end
end
