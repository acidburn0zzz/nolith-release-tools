# frozen_string_literal: true

namespace :passing_build do
  desc "Find and optionally trigger a passing build for EE"
  task :ee, [:ref, :trigger_build] do |_t, args|
    project = ReleaseTools::Project::GitlabEe
    ref = args.fetch(:ref, 'master')

    ReleaseTools.logger.info('Searching for passing build', project: project, ref: ref)
    ReleaseTools::PassingBuild.new(project, ref).execute(args)
  end
end
