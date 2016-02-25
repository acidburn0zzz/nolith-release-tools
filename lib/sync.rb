require_relative 'remotes'
require_relative 'repository'
require 'colorize'

class Sync
  def initialize(remotes)
    @remotes = remotes
  end

  def execute(branch = 'master')
    sync(@remotes, branch)
  end

  private

  def sync(remotes, branch)
    source = remotes.first
    path = "gitlab-sync-#{Time.now.to_f}"
    repo = Repository.get(source, path)

    repo.pull(remotes, branch)

    remotes.each do |remote|
      repo.push(remote, branch)
    end
  end
end
