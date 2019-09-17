# frozen_string_literal: true

namespace :auto_deploy do
  task :check_enabled do
    if ReleaseTools::Feature.disabled?(:auto_deploy)
      ReleaseTools.logger.warn("The `auto_deploy` feature flag is currently disabled.")
      exit
    end
  end

  desc "Prepare for auto-deploy by creating branches from the latest green commit on gitlab and omnibus-gitlab"
  task prepare: :check_enabled do
    results = ReleaseTools::Services::AutoDeployBranchService
      .new(ReleaseTools::AutoDeploy::Naming.branch)
      .create_branches!

    ReleaseTools::Slack::AutoDeployNotification
      .on_create(results)
  end

  def auto_deploy_pick(project, version)
    ReleaseTools.logger.info(
      'Picking into auto-deploy branch',
      project: project,
      name: version.auto_deploy_branch.branch_name
    )

    ReleaseTools::CherryPick::Service
      .new(project, version, version.auto_deploy_branch)
      .execute
  end

  desc 'Pick commits into the auto deploy branches'
  task pick: :check_enabled do
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
      ReleaseTools.logger.info(
        'Triggering merge train for auto-deploy branch',
        name: auto_deploy_branch
      )

      pipeline = ReleaseTools::GitlabOpsClient.run_trigger(
        ReleaseTools::Project::MergeTrain,
        ENV.fetch('MERGE_TRAIN_TRIGGER_TOKEN'),
        'master',
        SOURCE_BRANCH: auto_deploy_branch,
        TARGET_BRANCH: auto_deploy_branch,
        MERGE_MANUAL: '1'
      )

      ReleaseTools.logger.info('Merge-train triggered', url: pipeline.web_url)
    end
  end

  desc "Tag the auto-deploy branches from the latest passing builds"
  task tag: :check_enabled do
    Rake::Task['passing_build:ee'].invoke(ENV['AUTO_DEPLOY_BRANCH'], true)
  end
end
