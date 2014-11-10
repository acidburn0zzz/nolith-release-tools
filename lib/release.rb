require_relative 'version'
require_relative 'remotes'
require_relative 'repository'
require 'colorize'

class Release
  include Remotes

  def initialize(version)
    @version = version
  end

  def execute
    puts "Prepare repository...".colorize(:green)
    prepare_repo

    # CE release
    puts "\nCE release".colorize(:blue)
    prepare_branch(branch, 'ce-0', ce_remotes)
    bump_version(version, branch, ce_remotes)
    create_tag(tag, branch, ce_remotes)

    # EE release
    puts "\nEE release".colorize(:blue)
    prepare_branch(branch_ee, 'ee-0', ee_remotes)
    bump_version(version_ee, branch_ee, ee_remotes)
    create_tag(tag_ee, branch_ee, ee_remotes)
  end

  def prepare_branch(branch, base_remote, remotes)
    repository.ensure_branch_exists(branch, base_remote)
    remotes.each do |remote|
      repository.pull(branch, remote)
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
    @repository ||= Repository.get(dev_ce_repo)
  end

  def version
    @version
  end

  def tag
    Version.tag(version)
  end

  def branch
    Version.branch_name(@version)
  end

  def version_ee
    version + '-ee'
  end

  def tag_ee
    Version.tag(version) + '-ee'
  end

  def branch_ee
    branch + '-ee'
  end

  def prepare_repo
    ce_remotes.each_with_index do |remote, i|
      repository.add_remote("ce-#{i}", remote)
    end

    ee_remotes.each_with_index do |remote, i|
      repository.add_remote("ee-#{i}", remote)
    end

    repository.fetch
  end
end
