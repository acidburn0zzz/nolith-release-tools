module Remotes
  def self.ce_remotes
    [
      'git@dev.gitlab.org:gitlab/gitlabhq.git',
      'git@github.com:gitlabhq/gitlabhq.git',
      'git@gitlab.com:gitlab-org/gitlab-ce.git'
    ]
  end

  def self.ee_remotes
    [
      'git@gitlab.com:gitlab-org/gitlab-ee.git',
      'git@dev.gitlab.org:gitlab/gitlab-ee.git'
    ]
  end
end
