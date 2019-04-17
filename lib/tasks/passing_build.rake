# frozen_string_literal: true

namespace :passing_build do
  def passing_build(project, ref)
    $stdout.print '--> '.colorize(:green)
    $stdout.puts "Searching for passing build on #{project}@#{ref}..."

    ReleaseTools::PassingBuild.new(project, ref)
  end

  desc "Find and optionally trigger a passing build for EE"
  task :ee, [:ref, :trigger_build] do |_t, args|
    ref = args.fetch(:ref, 'master').dup
    # HACK: Allow `X-Y-stable` as an argument for both tasks, except master
    ref << '-ee' unless ref == 'master'

    passing_build(ReleaseTools::Project::GitlabEe, ref).execute(args)
  end

  desc "Find and optionally trigger a passing build for CE"
  task :ce, [:ref, :trigger_build] do |_t, args|
    ref = args.fetch(:ref, 'master').dup

    passing_build(ReleaseTools::Project::GitlabCe, ref).execute(args)
  end

  desc "Find and optionally trigger a passing build for Omnibus"
  task :omnibus, [:ref, :trigger_build] do |_t, args|
    ref = args.fetch(:ref, 'master').dup

    passing_build(ReleaseTools::Project::OmnibusGitlab, ref).execute(args)
  end

  desc "Trigger a green master build for both CE and EE"
  task :all, [:ref, :trigger_build] do |_t, args|
    Rake::Task['passing_build:ee'].invoke(*args)
    Rake::Task['passing_build:ce'].invoke(*args)
  end
end
