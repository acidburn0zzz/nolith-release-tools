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
      'git@gitlab.com:gitlab-org/gitlab-ee.git',
      'git@dev.gitlab.org:gitlab/gitlab-ee.git'
    ]
  end

  def all_remotes
    ce_remotes + ee_remotes
  end
end
