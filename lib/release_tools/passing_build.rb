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
      commit = ReleaseTools::ComponentVersions.update_omnibus(ref, version_map)

      url = commit_url(ReleaseTools::Project::OmnibusGitlab, commit.short_id)

      $stdout.puts "Updated Omnibus versions at #{url}".indent(4)

      # TODO: Tagging
    end

    private

    def commit_url(project, id)
      "https://gitlab.com/#{project.path}/commit/#{id}"
    end
  end
end
