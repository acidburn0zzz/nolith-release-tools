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

      versions = ReleaseTools::ComponentVersions.get(project, commit.id)

      versions.each do |component, version|
        $stdout.puts "#{component}: #{version}".indent(4)
      end

      trigger_build(versions) if args.trigger_build
    end

    def trigger_build(version_map)
      if ref.match?(/\A\d+-\d+-auto-deploy-\d+\z/)
        update_omnibus(version_map).tap do |commit|
          tag_omnibus(commit, version_map)
        end
      else
        trigger_branch_build(version_map)
      end
    end

    private

    def update_omnibus(version_map)
      commit = ReleaseTools::ComponentVersions.update_omnibus(ref, version_map)

      url = commit_url(ReleaseTools::Project::OmnibusGitlab, commit.short_id)
      $stdout.puts "Updated Omnibus versions at #{url}".indent(4)

      commit
    end

    def tag_omnibus(commit, version_map)
      tag_name = ReleaseTools::AutoDeploy::Naming.tag(
        ee_ref: version_map['VERSION'],
        omnibus_ref: commit.id
      )

      project = ReleaseTools::Project::OmnibusGitlab

      $stdout.puts "Creating `#{project}` tag `#{tag_name}`".indent(4)

      ReleaseTools::GitlabClient.create_tag(
        project,
        tag_name,
        commit.id
      )
    end

    def trigger_branch_build(version_map)
      pipeline_id = ENV.fetch('CI_PIPELINE_ID', 'pipeline_id_unset')
      branch_name = "#{ref}-#{pipeline_id}"

      $stdout.puts "Creating `#{project}` branch `#{branch_name}`"
      ReleaseTools::GitlabDevClient.create_branch(branch_name, ref, project)

      ReleaseTools::Pipeline.new(
        project,
        ref,
        version_map
      ).trigger

      $stdout.puts "Deleting `#{project}` branch `#{branch_name}`"
      ReleaseTools::GitlabDevClient.delete_branch(branch_name, project)
    end

    def commit_url(project, id)
      "https://gitlab.com/#{project.path}/commit/#{id}"
    end
  end
end
