require_relative 'remotes'
require_relative 'repository'
require 'colorize'

class Sync
  include Remotes

  def execute(branch = 'master')
    sync(dev_ce_repo, ce_remotes, branch)
    sync(dev_ee_repo, ee_remotes, branch)
  end

  private

  def sync(source, remotes, branch)
    path = File.join('/tmp', "gitlab-sync-#{Time.now.to_f}")
    repo = Repository.get(source, path)

    remotes.each do |remote|
      repo.pull(remote, branch)
    end

    remotes.each do |remote|
      repo.push(remote, branch)
    end
  end
end
