# frozen_string_literal: true

module ReleaseTools
  class GreenMaster
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def execute(args)
      commit = ReleaseTools::Commits.new(project, ref: 'master')
        .latest_dev_green_build_commit

      raise "Unable to find a passing build for `master` on dev" if commit.nil?

      $stdout.puts "Found #{project} green master at #{commit.id}"

      versions = ReleaseTools::ComponentVersions.get(project, commit)

      versions.each do |component, version|
        $stdout.puts "#{component}: #{version}".indent(2)
      end

      trigger_build(commit, versions) if args.trigger_build
    end

    def trigger_build(commit, versions)
      pipeline_id = ENV.fetch('CI_PIPELINE_IID', 'pipeline_id_unset')
      branch_name = "nightly-#{pipeline_id}"

      $stdout.puts "Creating branch #{branch_name}"
      dev_client.create_branch(branch_name, commit.id, project)

      ReleaseTools::Pipeline.new(
        project,
        commit.id,
        versions
      ).trigger

      $stdout.puts "Deleting branch #{branch_name}"
      dev_client.delete_branch(branch_name, project)
    end

    private

    def dev_client
      ReleaseTools::GitlabDevClient
    end
  end
end
