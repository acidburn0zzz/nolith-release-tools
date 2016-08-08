require 'version'

module Changelog
  # Updates a Markdown-based changelog document by inserting new Markdown
  # for a specified version above the appropriate previous version.
  #
  # This class expects that a Markdown document present at the provided file
  # path contains a Markdown-based changelog in the following format:
  #
  #     ## 8.10.1
  #
  #     - Entries
  #
  #     ## 8.10.0
  #
  #     - Entries
  #
  #     ## 8.9.6
  #
  #     - Entries
  #
  # When given a new minor version, for example 8.11.0, a changelog entry will
  # be added above the `## 8.10.1` entry. When given a new patch version for a
  # previous minor release, for example 8.9.7, the entry will be placed _above_
  # `## 8.9.6` but _below_ `## 8.10.0`.
  class Updater
    attr_reader :contents, :version

    # contents - Existing changelog content String
    # version  - Version object
    def initialize(contents, version)
      @contents = contents.lines
      @version  = version
    end

    # Insert some Markdown into an existing changelog based on the current
    # version and the version headers already present in the changelog.
    #
    # markdown - Markdown String to insert
    #
    # Returns the updated Markdown String
    def insert(markdown)
      contents.each_with_index do |line, index|
        if line.match(/^## (\d+\.\d+\.\d+)/)
          header = Version.new($1)

          if version.major >= header.major && version.minor >= header.minor
            contents.insert(index, *markdown.lines)
            break
          end
        end
      end

      contents.join
    end
  end
end
