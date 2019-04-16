# frozen_string_literal: true

module ReleaseTools
  class UpstreamMerge
    attr_reader :origin, :upstream, :source_branch, :target_branch

    CONFLICT_MARKER_REGEX = /\A(?<conflict_type>[ADU]{2}) /.freeze

    DownstreamAlreadyUpToDate = Class.new(StandardError)
    PushFailed = Class.new(StandardError)

    def initialize(origin:, upstream:, source_branch:, target_branch: 'master')
      @origin = origin
      @upstream = upstream
      @source_branch = source_branch
      @target_branch = target_branch
    end

    def execute!
      setup_merge_drivers
      prepare_upstream_merge
      conflicts = execute_upstream_merge
      after_upstream_merge

      conflicts
    end

    def dry_run
      setup_merge_drivers
      prepare_upstream_merge
    end

    private

    def repository
      @repository ||= RemoteRepository.get({ origin: origin, upstream: upstream }, global_depth: nil)
    end

    def setup_merge_drivers
      repo = Rugged::Repository.new(repository.path)

      repo.config['merge.merge_db_schema.name'] = 'Merge db/schema.rb'
      repo.config['merge.merge_db_schema.driver'] = 'merge_db_schema %O %A %B'
      repo.config['merge.merge_db_schema.recursive'] = 'text'
    end

    def prepare_upstream_merge
      $stdout.puts "Prepare repository...".colorize(:green)
      # We fetch CE first to make sure our EE copy is more up-to-date!
      repository.fetch(target_branch, remote: :upstream)
      repository.fetch(target_branch, remote: :origin)
      repository.ensure_branch_exists(source_branch)
      repository.configure_upstream_to(target_branch)
    end

    def execute_upstream_merge
      result = repository.merge("upstream/#{target_branch}", source_branch, no_ff: true)

      # Depending on Git version, it's "up-to-date" or "up to date"...
      raise DownstreamAlreadyUpToDate if result.output =~ /\AAlready up[\s\-]to[\s\-]date/

      conflicts = compute_conflicts
      conflicting_files = conflicts.map { |conflict_data| conflict_data[:path] }

      if conflicts.present?
        repository.commit(conflicting_files, no_edit: true)
        add_ci_skip_to_merge_commit
        add_latest_modifier_to_conflicts(conflicts)
      end

      raise PushFailed unless repository.push(origin, source_branch)

      conflicts
    end

    def after_upstream_merge
      repository.cleanup
    end

    def compute_conflicts
      repository.status(short: true).lines.each_with_object([]) do |line, files|
        path = line.sub(CONFLICT_MARKER_REGEX, '').chomp
        # Store the file as key and conflict type as value, e.g.: { path: 'foo.rb', conflict_type: 'UU' }
        if line =~ CONFLICT_MARKER_REGEX
          files << { path: path, conflict_type: $LAST_MATCH_INFO[:conflict_type] }
        end
      end
    end

    def add_ci_skip_to_merge_commit
      repository.commit(nil, amend: true, message: "#{latest_commit_message}\n[ci skip]")
    end

    def latest_commit_message
      repository.log(latest: true, format: :message).chomp
    end

    def add_latest_modifier_to_conflicts(conflicts)
      conflicts.each do |conflict|
        conflict[:user] = latest_modifier(conflict[:path])
      end
    end

    def latest_modifier(file)
      repository.log(latest: true, no_merges: true, format: :author, paths: file).lines.first.chomp
    end
  end
end
