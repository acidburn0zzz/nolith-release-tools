# frozen_string_literal: true

module ReleaseTools
  class PassingBuild
    attr_reader :project, :ref

    def initialize(project, ref)
      @project = project
      @ref = ref
    end

    def execute(args)
      commit = ReleaseTools::Commits.new(project, ref: ref)
        .latest_dev_green_build_commit

      if commit.nil?
        raise "Unable to find a passing #{project} build for `#{ref}` on dev"
      end

      $stdout.puts "Found at #{commit.id}".indent(4)

      versions = ReleaseTools::ComponentVersions.get(project, commit)

      versions.each do |component, version|
        $stdout.puts "#{component}: #{version}".indent(6)
      end

      trigger_build(commit, versions) if args.trigger_build
    end

    def trigger_build(commit, versions)
      pipeline_id = ENV.fetch('CI_PIPELINE_ID', 'pipeline_id_unset')
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
