require 'colorize'

require_relative 'remotes'
require_relative 'repository'
require_relative 'version'

class Release
  extend Forwardable

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

  attr_reader :version, :remotes, :options

  def_delegator :version, :tag
  def_delegator :version, :stable_branch, :branch

  def initialize(version, remotes, opts = {})
    @version = version_class.new(version)
    @remotes = remotes
    @options = opts
  end

  def execute
    prepare_release
    execute_release
    after_execute_hook
    after_release
  end

  private

  def repository
    @repository ||= Repository.get(remotes)
  end

  def prepare_release
    puts "Prepare repository...".colorize(:green)
    repository.ensure_branch_exists(branch)
    repository.pull_from_all_remotes(branch)
  end

  def execute_release
    bump_versions
    push_ref('branch', branch)
    create_tag
    push_ref('tag', tag)
  end

  def after_release
    repository.cleanup
  end

  # Overridable
  def after_execute_hook
    true
  end

  # Overridable
  def version_class
    Version
  end

  # Overridable
  def bump_versions
    bump_version('VERSION', version)
  end

  def bump_version(file_name, version)
    puts "Update #{file_name} to #{version}...".colorize(:green)
    repository.write_file(file_name, "#{version}\n")
    repository.commit(file_name, "Update #{file_name} to #{version}")
  end

  def create_tag
    puts "Create git tag #{tag}...".colorize(:green)
    repository.create_tag(tag)
  end

  def push_ref(ref_type, ref)
    puts "Push #{ref_type} #{ref} to all remotes...".colorize(:green)
    repository.push_to_all_remotes(ref)
  end
end
