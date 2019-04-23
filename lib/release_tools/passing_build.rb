# frozen_string_literal: true

require 'active_support/core_ext/string/access'

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

      # TODO: Move up to Rake task so it's explicit, and isolate $stdout
      if args.trigger_build
        commit = update_omnibus(versions)
        tag_omnibus(commit, versions)
      end
    end

    def update_omnibus(version_map)
      ReleaseTools::ComponentVersions.update_omnibus(ref, version_map).tap do |commit|
        url = commit_url(ReleaseTools::Project::OmnibusGitlab, commit.short_id)

        $stdout.puts "Updated Omnibus versions at #{url}".indent(4)
      end
    end

    def tag_omnibus(commit, versions)
      prod_client = ReleaseTools::GitlabClient

      tag_name = ReleaseTools::AutoDeploy::Naming.tag(
        ee_ref: versions['VERSION'],
        omnibus_ref: commit.id
      )

      prod_client.create_tag(
        ReleaseTools::Project::OmnibusGitlab,
        tag_name,
        commit.id
      )
    end

    private

    def commit_url(project, id)
      "https://gitlab.com/#{project.path}/commit/#{id}"
    end
  end
end
