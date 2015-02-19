module Remotes
  extend self

  def ce_remotes
    [
      'git@dev.gitlab.org:gitlab/gitlabhq.git',
      'git@github.com:gitlabhq/gitlabhq.git',
      'git@gitlab.com:gitlab-org/gitlab-ce.git'
    ]
  end

  def ee_remotes
    [
      'git@gitlab.com:subscribers/gitlab-ee.git',
      'git@dev.gitlab.org:gitlab/gitlab-ee.git'
    ]
  end

  def ci_remotes
    [
      'git@dev.gitlab.org:gitlab/gitlab-ci.git',
      'git@github.com:gitlabhq/gitlab-ci.git',
      'git@gitlab.com:gitlab-org/gitlab-ci.git'
    ]
  end

  def all_remotes
    ce_remotes + ee_remotes + ci_remotes
  end
end
