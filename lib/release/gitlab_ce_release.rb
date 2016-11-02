require_relative '../remotes'
require_relative 'base_release'
require_relative 'omnibus_gitlab_release'

module Release
  class GitlabCeRelease < BaseRelease
    private

    def remotes
      Remotes.remotes(:ce, dev_only: options[:security])
    end

    def after_execute_hook
      Release::OmnibusGitLabRelease.new(
        version,
        options.merge(gitlab_repo_path: repository.path)
      ).execute
    end

    def after_release
      tag_next_minor_pre_version

      super
    end

    def tag_next_minor_pre_version
      return unless version.release? && version.patch.zero?

      repository.ensure_branch_exists('master')
      repository.pull_from_all_remotes('master')
      bump_version('VERSION', "#{version.next_minor}-pre")
      push_ref('branch', 'master')

      next_minor_pre_tag = "v#{version.next_minor}.pre"
      create_tag(next_minor_pre_tag)
      push_ref('tag', next_minor_pre_tag)
    end
  end
end
