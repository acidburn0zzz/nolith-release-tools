require 'colorize'

require_relative 'remotes'
require_relative 'repository'
require_relative 'version'

class Release
  # Get the Date of the next release
  #
  # Defaults to the 22nd of the current month, or next month if the current one
  # is half over.
  #
  # Returns a Date
  def self.next_date
    today = Date.today

    next_date = Date.new(today.year, today.month, 22)
    next_date = next_date.next_month if today.day >= 15

    next_date
  end

  attr_reader :version, :remotes

  def initialize(version_string, remotes)
    @version = Version.new(version_string)
    @remotes = remotes
    @omnibus = false
  end

  def execute
    puts "Prepare repository...".colorize(:green)
    prepare_repo(remotes)
    prepare_branch(branch, 'remote-0', remotes)
    bump_version(version, branch, remotes)
    create_tag(tag, branch, remotes)
    do_omnibus
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
    @repository ||= if @omnibus
                      o_remote = Remotes.omnibus_gitlab_remotes.first
                      o_path = o_remote.split('/').last.sub(/\.git\Z/, '')
                      Repository.get(o_remote, o_path)
                    else
                      Repository.get(remotes.first, path)
                    end
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

  def do_omnibus
    do_omnibus_reinitialize
    prepare_repo(remotes)
    prepare_branch(branch, 'remote-0', remotes)
    if set_revisions?
      bump_version(version, branch, remotes)
      create_tag(version.to_omnibus(ee: version.end_with?('-ee')), branch, remotes)
    end
  end

  def do_omnibus_reinitialize
    @omnibus = true
    @repository = nil
    @remotes = Remotes.omnibus_gitlab_remotes
  end

  def set_revisions?
    if prepare_component_versions.nil?
      nil
    else
      true
    end
  end

  def prepare_component_versions
    %w( VERSION GITLAB_SHELL_VERSION GITLAB_WORKHORSE_VERSION ).each do |f|
      version = read_version_file(f)
      updated = update_version_file(f, version)
      return nil if updated.nil?
    end
  end

  def read_version_file(file_name)
    file_path = File.join(path, file_name)
    if File.exists?(file_path)
      File.read(file_path).strip
    else
      puts "Couldn't read #{file_name} in #{path}".colorize(:red)
      nil
    end
  end

  def update_version_file(file_name, version)
    return if version.nil?
    file_path = File.join(path, file_name)
    if File.exists?(file_path)
      File.open(file_path, "w"){ |file| file.write(version) }
    else
      puts "Couldn't write to #{file_name} in #{path}".colorize(:red)
      nil
    end
  end
end
