module CherryPick
  # Performs automated cherry picking to a preparation branch for the specified
  # version.
  #
  # For the given project, this service will look for merged merge requests on
  # that project labeled `Pick into X.Y` and attempt to cherry-pick their merge
  # commits into the preparation merge request for the specified version.
  #
  # It will post a comment to each merge request with the status of the pick,
  # and then a final summary message to the preparation merge request with the
  # list of picked and unpicked merge requests for the release managers to
  # perform any further manual actions.
  class Service
    # TODO (rspeicher): Support `SharedStatus.security_release?`
    REMOTE = :gitlab

    attr_reader :project
    attr_reader :version

    def initialize(project, version)
      @project = project
      @version = version

      assert_version!

      @prep_mr = PreparationMergeRequest.new(version: version)
      @prep_branch = @prep_mr.preparation_branch_name
      @results = []

      assert_prep_mr!
    end

    def execute
      return unless pickable_mrs.any?

      clone_repository
      checkout_branch

      pickable_mrs.each do |merge_request|
        cherry_pick(merge_request)
      end

      push

      notifier.summary(
        @results.select(&:success?),
        @results.select(&:failure?)
      )
    end

    private

    attr_reader :repository

    def assert_version!
      raise "Invalid version provided: `#{version}`" unless version.valid?
    end

    def assert_prep_mr!
      unless @prep_mr.exists?
        raise "Preparation merge request not found for `#{version}`"
      end
    end

    def notifier
      @notifier ||= ::CherryPick::CommentNotifier.new(version, @prep_mr)
    end

    def clone_repository
      remote = RemoteRepository.get(
        # We only need a single remote
        project.remotes.slice(REMOTE),

        # We need the prep branch and all of the merge commits we're picking, so
        # do a full clone
        #
        # TODO (rspeicher): Can we find a suitable depth to avoid this?
        global_depth: nil
      )
      remote.ensure_branch_exists(@prep_branch)

      @repository = Rugged::Repository.new(remote.path)
    end

    def checkout_branch
      repository.checkout("#{REMOTE}/#{@prep_branch}", strategy: :force)
    end

    def cherry_pick(merge_request)
      result = nil

      # Wipe out any possible uncommitted changes from a previous (failed) pick
      repository.reset('HEAD', :hard)

      commit = repository.lookup(merge_request.merge_commit_sha)
      repository.cherrypick(commit.oid, mainline: 1)
      commit_pick(commit)

      result = Result.new(merge_request, :success)
    rescue Rugged::IndexError, Rugged::MergeError, Rugged::OdbError
      conflicts = repository.index.conflicts
        .flat_map(&:values)
        .flat_map { |c| c[:path] }
        .uniq

      result = Result.new(merge_request, :failure, conflicts)
    ensure
      repository.reset('HEAD', :hard)

      record_result(result)
    end

    # Given the cherry-picked commit, commit the changes of the pick
    #
    # commit - Rugged::Commit instance
    def commit_pick(commit)
      Rugged::Commit.create(
        repository,
        tree: repository.index.write_tree,
        update_ref: 'HEAD',
        parents: [repository.last_commit],
        author: commit.author,
        committer: commit.committer,
        message: commit.message
      )
    end

    def push
      repository.push(REMOTE, @prep_branch)
    end

    def record_result(result)
      @results << result
      notifier.comment(result)
    end

    def pickable_mrs
      @pickable_mrs ||=
        GitlabClient.merge_requests(
          project,
          state: 'merged',
          labels: PickIntoLabel.for(version),
          order_by: 'created_at',
          sort: 'asc'
        )
    end
  end
end
