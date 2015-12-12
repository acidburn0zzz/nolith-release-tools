require_relative 'version'
require_relative 'remotes'
require_relative 'repository'
require 'colorize'

class Release
  # Get the Date of the next release
  #
  # Defaults to the 22nd of the current month, or next month if the current one
  # is half over.
  #
  # Returns a Date
  def self.next_release_date
    today = Date.today

    next_date = Date.new(today.year, today.month, 22)
    next_date = next_date.next_month if today.day >= 15

    next_date
  end

  attr_reader :version, :remotes

  def initialize(version_string, remotes)
    @version = Version.new(version_string)
    @remotes = remotes
  end

  def execute
    puts "Prepare repository...".colorize(:green)
    prepare_repo(remotes)
    prepare_branch(branch, 'remote-0', remotes)
    bump_version(version, branch, remotes)
    create_tag(tag, branch, remotes)
  end

  def prepare_branch(branch, base_remote, remotes)
    repository.ensure_branch_exists(branch, base_remote)
    remotes.each do |remote|
      repository.pull(remote, branch)
    end
  end

  def bump_version(version, branch, remotes)
    puts "Bump VERSION to #{version}".colorize(:green)
    repository.commit('VERSION', version, "Version #{version}", branch)

    remotes.each do |remote|
      puts "Push branch #{branch} to #{remote}".colorize(:green)
      repository.push(remote, branch)
    end
  end

  def create_tag(tag, branch, remotes)
    puts "Create git tag #{tag}".colorize(:green)
    repository.create_tag(branch)

    remotes.each do |remote|
      puts "Push tag #{tag} to #{remote}".colorize(:green)
      repository.push(remote, tag)
    end
  end

  def repository
    @repository ||= Repository.get(remotes.first, path)
  end

  def path
    remotes.first.split('/').last.sub(/\.git\Z/, '')
  end

  def version
    @version
  end

  def tag
    version.tag
  end

  def branch
    version.stable_branch
  end

  def prepare_repo(remotes)
    remotes.each_with_index do |remote, i|
      repository.add_remote("remote-#{i}", remote)
    end

    repository.fetch
  end
end
