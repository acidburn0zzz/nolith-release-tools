module Remotes
  def github_ce_repo
    'git@github.com:gitlabhq/gitlabhq.git'
  end

  def gitlab_ce_repo
    'git@gitlab.com:gitlab-org/gitlab-ce.git'
  end

  def dev_ce_repo
    'git@dev.gitlab.org:gitlab/gitlabhq.git'
  end

  def gitlab_ee_repo
    'git@gitlab.com:subscribers/gitlab-ee.git'
  end

  def dev_ee_repo
    'git@dev.gitlab.org:gitlab/gitlab-ee.git'
  end

  def test_repo
    'git@dev.gitlab.org:samples/test-release-tool.git'
  end

  def ce_remotes
    [dev_ce_repo, github_ce_repo, gitlab_ce_repo]
  end

  def ee_remotes
    [dev_ee_repo, gitlab_ee_repo]
  end

  def all_remotes
    ce_remotes + ee_remotes
  end
end
