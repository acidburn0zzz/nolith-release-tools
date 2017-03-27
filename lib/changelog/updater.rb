require_relative '../version'

module Changelog
  # Updates a Markdown changelog String by inserting new Markdown for a
  # specified version above the appropriate previous version.
  #
  # This class expects that the provided Markdown String contains a changelog in
  # the following format:
  #
  #     ## 8.10.1 (2016-07-25)
  #
  #     - Entries
  #
  #     ## 8.10.0 (2016-07-22)
  #
  #     - Entries
  #
  #     ## 8.9.6 (2016-07-11)
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
        if line =~ /\A## (\d+\.\d+\.\d+)/
          header = Version.new($1)

          if version.to_ce == header
            entries = markdown.lines
            entries.shift(2) # Remove the header and the blank line
            entries.pop      # Remove the trailing blank line

            # Insert the entries below the existing header and its blank line
            contents.insert(index + 2, entries)
            break
          elsif version >= header
            contents.insert(index, *markdown.lines)
            break
          end
        end
      end

      contents
        .flatten
        .map { |line| line.force_encoding(Encoding::UTF_8) }
        .join
    end
  end
end
