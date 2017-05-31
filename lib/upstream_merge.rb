require_relative 'remote_repository'

class UpstreamMerge
  attr_reader :origin, :upstream, :merge_branch

  CONFLICT_MARKER_REGEX = /\A[A-Z]{2} /

  def initialize(origin:, upstream:, merge_branch:)
    @origin = origin
    @upstream = upstream
    @merge_branch = merge_branch
  end

  def execute
    prepare_upstream_merge
    execute_upstream_merge
    after_upstream_merge

    conflicts_data
  end

  private

  def repository
    @repository ||= RemoteRepository.get({ origin: origin, upstream: upstream }, global_depth: 200)
  end

  def prepare_upstream_merge
    $stdout.puts "Prepare repository...".colorize(:green)
    repository.checkout_new_branch(merge_branch)
  end

  def execute_upstream_merge
    merge_no_ff

    if conflicts?
      repository.commit(conflicting_files, no_edit: true)
      add_ci_skip_to_merge_commit
    end

    repository.push(origin, merge_branch)
  end

  def after_upstream_merge
    repository.cleanup
  end

  def merge_no_ff
    repository.fetch('master', remote: :upstream)
    repository.merge('upstream/master', merge_branch, no_ff: true)
  end

  def conflicts?
    conflicts_data.present?
  end

  def conflicts_data
    @conflicts_data ||= begin
      repository.status(short: true).lines.each_with_object([]) do |line, files|
        path = line.sub(CONFLICT_MARKER_REGEX, '').chomp
        # Store the file as key and conflict type as value, e.g.: { path: 'foo.rb', conflict_type: 'UU' }
        files << { user: last_modifier(path), path: path, conflict_type: line[0, 2] } if line =~ CONFLICT_MARKER_REGEX
      end
    end
  end

  def conflicting_files
    @conflicting_files ||= conflicts_data.map { |conflict_data| conflict_data[:path] }
  end

  def add_ci_skip_to_merge_commit
    repository.commit(nil, amend: true, message: latest_commit_message << "\n[ci skip]")
  end

  def latest_commit_message
    repository.log(latest: true, format: :message).chomp
  end

  def conflicting_file_checklist_item(user:, sha:, file:, conflict_type:)
    "- [ ] #{user} Please resolve https://gitlab.com/gitlab-org/gitlab-ee/blob/#{sha}/#{file} (#{conflict_type})"
  end

  def last_modifier(file)
    repository.log(paths: file, no_merges: true, format: :author).lines.first.chomp
  end
end
