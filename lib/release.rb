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
  end

  def execute
    puts "Prepare repository...".colorize(:green)
    prepare_repo(remotes)
    prepare_branch(branch, 'remote-0', remotes)
    bump_version(version, branch, remotes)
    create_tag(tag, branch, remotes)
    do_omnibus(path)
  end

  def prepare_branch(branch, base_remote, remotes)
    repository.ensure_branch_exists(branch, base_remote)
    remotes.each do |remote|
      repository.pull(remote, branch)
    end
  end

  def bump_version(version, branch, remotes)
    puts "Bump VERSION to #{version}".colorize(:green)
    repository.checkout_and_write(branch, 'VERSION', version)
    repository.commit('VERSION', "Version #{version}")

    push_remotes(branch, remotes)
  end

  def push_remotes(branch, remotes)
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

  def do_omnibus(repository_path)
    do_omnibus_reinitialize
    prepare_repo(remotes)
    prepare_branch(branch, 'remote-0', remotes)
    if set_revisions?(repository_path)
      bump_version_files(branch, remotes)
      create_tag(version.to_omnibus(ee: version.ee?), branch, remotes)
    end
  end

  def do_omnibus_reinitialize
    @remotes = Remotes.omnibus_gitlab_remotes
    @repository = nil
  end

  def version_files
    %w( VERSION GITLAB_SHELL_VERSION GITLAB_WORKHORSE_VERSION )
  end

  def set_revisions?(repository_path)
    prepare_component_versions(repository_path).nil?
  end

  def bump_version_files(branch, remotes)
    repository.checkout_branch(branch)
    version_files.each do |f|
      repository.commit(f, "Update version in #{f}")
    end

    push_remotes(branch, remotes)
  end

  def prepare_component_versions(repository_path)
    version_files.each do |f|
      updated = update_version_file(repository_path, f)
      return nil if updated.nil?
    end
  end

  def read_version_file(repository_path, file_name)
    repository_file_path = File.join(File.join('/tmp', repository_path), file_name)
    if File.exists?(repository_file_path)
      File.read(repository_file_path).strip
    else
      puts "Couldn't read #{file_name} in #{repository_file_path}".colorize(:red)
      nil
    end
  end

  def update_version_file(repository_path, file_name)
    file_path = File.join(File.join('/tmp', path), file_name)
    if File.exists?(file_path)
      version = read_version_file(repository_path, file_name)
      return nil if version.nil?
      puts "Writing #{version} to #{file_path}".colorize(:green)
      File.open(file_path, "w"){ |file| file.write("#{version}\n") }
      true
    else
      puts "Couldn't write to #{file_name} in #{file_path}".colorize(:red)
      nil
    end
  end
end
