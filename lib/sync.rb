require_relative 'repository'

class Sync

  attr_reader :remotes

  def initialize(remotes)
    @remotes = remotes
  end

  def execute(branch = 'master')
    sync(branch)
  end

  private

  def sync(branch)
    repository = Repository.get(remotes, "gitlab-sync-#{Time.now.to_i}")

    repository.pull_from_all_remotes(branch)
    repository.push_to_all_remotes(branch)
  end
end
