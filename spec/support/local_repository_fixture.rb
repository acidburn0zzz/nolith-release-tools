require 'fileutils'
require 'rugged'

class LocalRepositoryFixture
  attr_reader :repository

  def self.repository_name
    'repo'
  end

  def rebuild_fixture!
    wipe_fixture!

    @repository = Rugged::Repository.init_at(fixture_path)

    commit(
      path:    'README.md',
      content: 'Sample README.md',
      message: 'Add empty README.md'
    )
  end

  def wipe_fixture!
    FileUtils.rm_r(fixture_path) if Dir.exist?(fixture_path)
    FileUtils.mkdir_p(fixture_path)
  end

  def fixture_path
    File.expand_path(
      "../fixtures/repositories/#{self.class.repository_name}",
      __dir__
    )
  end

  private

  def commit(path:, content:, message:)
    index = repository.index

    oid = repository.write(content, :blob)
    index.add(path: path, oid: oid, mode: 0o100644)

    commit = Rugged::Commit.create(
      repository,
      tree: index.write_tree(repository),
      message: message,
      parents: repository.empty? ? [] : [repository.head.target].compact,
      update_ref: 'HEAD'
    )

    repository.checkout_head(strategy: :force)

    commit
  end
end
