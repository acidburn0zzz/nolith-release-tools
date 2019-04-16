# frozen_string_literal: true

namespace :green_master do
  desc "Find and optionally trigger a green master build for EE"
  task :ee, [:trigger_build] do |_t, args|
    ReleaseTools::GreenMaster
      .new(ReleaseTools::Project::GitlabEe)
      .execute(args)
  end

  desc "Find and optionally trigger a green master build for CE"
  task :ce, [:trigger_build] do |_t, args|
    ReleaseTools::GreenMaster
      .new(ReleaseTools::Project::GitlabCe)
      .execute(args)
  end

  desc "Trigger a green master build for both CE and EE"
  task :all, [:trigger_build] do |_t, args|
    Rake::Task['green_master:ee'].invoke(args.trigger_build)
    Rake::Task['green_master:ce'].invoke(args.trigger_build)
  end
end
