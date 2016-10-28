module RuggedMatchers
  extend RSpec::Matchers::DSL

  def deltas(commit)
    commit.diff(reverse: true).deltas
  end

  # Verify that `commit`'s tree contains `file_path`
  matcher :have_blob do |file_path|
    match do |commit|
      tree = commit.tree

      tree.walk(:preorder).one? do |root, entry|
        File.join(root, entry[:name]) == file_path
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
end
