require 'fileutils'
require 'rugged'

require_relative 'repository_fixture'

class LocalRepositoryFixture
  include RepositoryFixture

  def self.repository_name
    'repo'
  end

  def build_fixture(options = {})
    commit_blob(
      path:    'README.md',
      content: 'Sample README.md',
      message: 'Add empty README.md'
    )
  end
end
