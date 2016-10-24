module Remotes
  require 'active_support/core_ext/hash/slice'

  CE_REMOTES =
    {
      dev: 'git@dev.gitlab.org:gitlab/gitlabhq.git',
      gitlab: 'git@gitlab.com:gitlab-org/gitlab-ce.git',
      github: 'git@github.com:gitlabhq/gitlabhq.git'
    }.freeze

  EE_REMOTES =
    {
      dev: 'git@dev.gitlab.org:gitlab/gitlab-ee.git',
      gitlab: 'git@gitlab.com:gitlab-org/gitlab-ee.git'
    }.freeze

  OMNIBUS_GITLAB_REMOTES =
    {
      dev: 'git@dev.gitlab.org:gitlab/omnibus-gitlab.git',
      gitlab: 'git@gitlab.com:gitlab-org/omnibus-gitlab.git',
      github: 'git@github.com:gitlabhq/omnibus-gitlab.git'
    }.freeze

  def self.remotes(repo_key, dev_only: false)
    remotes =
      case repo_key
      when :ce
        CE_REMOTES
      when :ee
        EE_REMOTES
      when :omnibus_gitlab
        OMNIBUS_GITLAB_REMOTES
      end

    if dev_only
      remotes.slice(:dev)
    else
      remotes
    end
  end
end
