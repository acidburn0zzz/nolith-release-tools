require_relative 'version'
require_relative 'remotes'
require_relative 'git'

class ReleaseCandidate
  include Remotes

  def initialize(version)
    @version = version
    @rc_version = Version.rc1(version)
    @git = Git.new('/tmp/gitlabhq')
  end

  def execute
    Dir.chdir("/tmp") do
      system *%W(git clone --depth=5 #{dev_ce_repo})

      @git = Git.new('/tmp/gitlabhq')
      @git.add_remote 'gl', gitlab_ce_repo
      @git.add_remote 'gh', github_ce_repo
      @git.commit('VERSION', @rc_version, "Version #{@rc_version}")
      @git.create_tag
      @git.create_stable(Version.branch_name(@version))
    end
  end
end
