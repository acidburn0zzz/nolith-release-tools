module RuggedMatchers
  extend RSpec::Matchers::DSL

  def deltas(commit)
    commit.diff(reverse: true).deltas
  end

  # Read a blob at `path` from a repository's current HEAD
  #
  # repository - Rugged::Repository object
  # path       - Path String
  #
  # Returns a stripped String
  def read_head_blob(repository, path)
    head = repository.head

    repository
      .blob_at(head.target_id, path)
      .content
      .strip
  end

  # Verify that `commit`'s tree contains `file_path`
  matcher :have_blob do |file_path|
    match do |commit|
      tree = commit.tree

      tree.walk(:preorder).one? do |root, entry|
        File.join(root, entry[:name]).sub(%r{\A/}, '') == file_path
      end
    end

    failure_message do |commit|
      "expected #{file_path} to exist in tree for #{commit.oid}"
    end

    failure_message_when_negated do |commit|
      "expected #{file_path} not to exist in tree for #{commit.oid}"
    end
  end

  # Verify that `commit` deleted `file_path`
  matcher :have_deleted do |file_path|
    match do |commit|
      deltas(commit).one? do |delta|
        delta.deleted? && delta.new_file[:path] == file_path
      end
    end

    failure_message do |commit|
      "expected #{file_path} to have been deleted by #{commit.oid}"
    end

    failure_message_when_negated do |commit|
      "expected #{file_path} not to have been deleted by #{commit.oid}"
    end
  end

  # Verify that `commit` modified `file_path`
  matcher :have_modified do |file_path|
    match do |commit|
      deltas(commit).one? do |delta|
        delta.modified? && delta.new_file[:path] == file_path
      end
    end

    failure_message do |commit|
      "expected #{file_path} to have been modified by #{commit.oid}"
    end

    failure_message_when_negated do |commit|
      "expected #{file_path} not to have been modified by #{commit.oid}"
    end
  end

  # Verify that `repository` has a version file at a specific version
  #
  # If no filename is given, `VERSION` will be read. Otherwise a
  # `GITLAB_[FILENAME]_VERSION` file will be read.
  #
  # Examples:
  #
  #   expect(repository).to have_version.at('1.2.3')
  #   expect(repository).to have_version('pages').at('2.3.4')
  #   expect(repository).to have_version('workhorse').at('3.4.5')
  #   expect(repository).not_to have_version('pages')
  matcher :have_version do |file_path|
    def normalize_path(file_path)
      if file_path.nil?
        'VERSION'
      else
        "GITLAB_#{file_path.upcase}_VERSION"
      end
    end

    match do |repository|
      @actual = normalize_path(file_path)

      begin
        read_head_blob(repository, @actual) == @version
      rescue NoMethodError
        false
      end
    end

    match_when_negated do |repository|
      @actual = normalize_path(file_path)

      begin
        read_head_blob(repository, @actual)
      rescue NoMethodError
        true
      else
        false
      end
    end

    chain :at do |version|
      @version = version
    end

    failure_message do
      "expected #{File.join(repository.workdir, @actual)} to be #{@version}"
    end

    failure_message_when_negated do
      "expected #{repository.workdir} not to contain #{@actual}"
    end
  end
end
