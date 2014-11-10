require_relative 'version'
require_relative 'remotes'
require_relative 'git'

class ReleaseCandidate
  include Remotes

  def initialize(version)
    @version = version
    @rc_version = Version.rc1(version)
    @stable_branch = Version.branch_name(version)
    @tag_rc1 = Version.tag_rc1(version)
    @dir_name = 'gitlabhq-' + @rc_version
    @git = Git.new(File.join('/tmp', @dir_name))
  end

  def execute
    Dir.chdir("/tmp") do
      system *%W(git clone #{dev_ce_repo} #{@dir_name})

      @git.add_remote 'gl', gitlab_ce_repo
      @git.add_remote 'gh', github_ce_repo
      @git.commit('VERSION', @rc_version, "Version #{@rc_version}")

      # Push version bump
      all_remotes.each do |remote|
        @git.push(remote, 'master')
      end

      @git.create_tag

      # Push tags
      all_remotes.each do |remote|
        @git.push(remote, @tag_rc1)
      end

      @git.create_stable(@stable_branch)

      # Push stable branches
      all_remotes.each do |remote|
        @git.push(remote, @stable_branch)
      end
    end
  end
end
