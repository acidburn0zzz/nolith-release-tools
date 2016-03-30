module Remotes
  def self.ce_remotes
    {
      dev: 'git@dev.gitlab.org:gitlab/gitlabhq.git',
      gitlab: 'git@gitlab.com:gitlab-org/gitlab-ce.git',
      github: 'git@github.com:gitlabhq/gitlabhq.git'
    }
  end

  def self.ee_remotes
    {
      dev: 'git@dev.gitlab.org:gitlab/gitlab-ee.git',
      gitlab: 'git@gitlab.com:gitlab-org/gitlab-ee.git'
    }
  end

  def self.omnibus_gitlab_remotes
    {
      dev: 'git@dev.gitlab.org:gitlab/omnibus-gitlab.git',
      gitlab: 'git@gitlab.com:gitlab-org/omnibus-gitlab.git',
      github: 'git@github.com:gitlabhq/omnibus-gitlab.git'
    }
  end
end
