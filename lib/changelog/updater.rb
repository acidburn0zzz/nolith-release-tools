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
    attr_reader :file_path, :version

    # file_path - Changelog file path String
    # version   - Version object
    def initialize(file_path, version)
      @file_path = file_path
      @version   = version
    end

    # Insert some Markdown into an existing changelog based on the current
    # version and the version headers already present in the changelog.
    #
    # markdown - Markdown String to insert
    #
    # Returns the updated Markdown String
    def insert(markdown)
      lines = File.readlines(file_path)

      lines.each_with_index do |line, index|
        if line.match(/^## (\d+\.\d+\.\d+)$/)
          header = Version.new($1)

          if version.major >= header.major && version.minor >= header.minor
            lines.insert(index, *markdown.lines)
            break
          end
        end
      end

      lines.join
    end

    # Insert the provided Markdown into an existing changelog and write to the
    # specified output.
    #
    # markdown - Markdown String to write
    # writer   - A callable object, accepting the updated Markdown String
    #
    # Example:
    #
    #   # Write the Markdown to a StringIO object
    #   output = StringIO.new
    #   writer = -> (contents) { output.write(contents) }
    #   write("Hi!", writer: writer)
    def write(markdown, writer: file_writer)
      writer.call(insert(markdown.to_s))
    end

    private

    def file_writer
      lambda do |contents|
        File.open(file_path, 'w') do |file|
          file.write(contents)
        end
      end
    end
  end
end
