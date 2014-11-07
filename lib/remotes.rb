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

  def test_ce_repo
    'git@dev.gitlab.org:samples/test-release-tools.git'
  end

  def all_remotes
    #[github_ce_repo, gitlab_ce_repo, dev_ce_repo]
    [test_ce_repo]
  end
end
