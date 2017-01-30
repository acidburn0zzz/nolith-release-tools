require 'colorize'
require 'forwardable'

require_relative '../changelog'
require_relative '../release'
require_relative '../repository'
require_relative '../version'
require_relative '../packagecloud_client'
require_relative '../gitlab_dev_client'

module Release
  class BaseRelease
    extend Forwardable

    attr_reader :version, :remotes, :options

    def_delegator :version, :tag
    def_delegator :version, :stable_branch

    def initialize(version, opts = {})
      @version = version_class.new(version)
      @options = opts
    end

    def execute
      if security_release?
        prepare_security_release
      else
        prepare_release
      end
      before_execute_hook
      execute_release
      after_execute_hook
      after_release
    end

    def security_release?
      options['SECURITY'] == 'true'
    end

    private

    def security_repository
      version_repo = to_minor.tr('.', '-')
      "security-#{version_repo}-#{Digest::MD5.hexdigest(version_repo)}"
    end

    def packagecloud
      @packagecloud ||= PackagecloudClient.new
    end

    # Overridable
    def remotes
      raise NotImplementedError
    end

    def repository
      @repository ||= Repository.get(remotes)
    end

    def prepare_release
      $stdout.puts "Prepare repository...".colorize(:green)
      repository.pull_from_all_remotes('master')
      repository.ensure_branch_exists(stable_branch)
      repository.pull_from_all_remotes(stable_branch)
    end

    def prepare_security_release
      $stdout.puts "Prepare security release...".colorize(:green)
      packagecloud.create_secret_repository(security_repository)
      unless GitlabDevClient.fetch_repo_variable
        GitlabDevClient.create_repo_variable(security_repository)
      end
    end

    # Overridable
    def before_execute_hook
      true
    end

    def execute_release
      repository.ensure_branch_exists(stable_branch)
      bump_versions
      push_ref('branch', stable_branch)
      push_ref('branch', 'master')
      create_tag(tag)
      push_ref('tag', tag)
    end

    # Overridable
    def after_execute_hook
      true
    end

    def after_release
      repository.cleanup
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
      $stdout.puts "Update #{file_name} to #{version}...".colorize(:green)
      repository.write_file(file_name, "#{version}\n")
      repository.commit(file_name, "Update #{file_name} to #{version}")
    end

    def create_tag(tag)
      $stdout.puts "Create git tag #{tag}...".colorize(:green)
      repository.create_tag(tag)
    end

    def push_ref(ref_type, ref)
      $stdout.puts "Push #{ref_type} #{ref} to all remotes...".colorize(:green)
      repository.push_to_all_remotes(ref)
    end
  end
end
