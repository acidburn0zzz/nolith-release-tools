require 'date'
require 'release'

module Changelog
  class MarkdownGenerator
    attr_reader :version, :entries

    def initialize(version, entries)
      @version = version
      @entries = entries
    end

    def to_s
      markdown = StringIO.new
      markdown.puts header
      markdown.puts

      if entries.empty?
        markdown.puts "- No changes."
      else
        sorted_entries.each do |entry|
          markdown.puts "- #{entry}"
        end
      end

      markdown.puts

      markdown.string
    end

    private

    def header
      "## #{version.to_patch} (#{date})"
    end

    def date
      if version.patch.zero?
        Release.next_date.strftime("%Y-%m-%d")
      else
        Date.today.strftime("%Y-%m-%d")
      end
    end

    # Sort entries in ascending order by ID
    #
    # Entries without an ID are placed last
    def sorted_entries
      entries.sort do |a,b|
        (a.id || 999_999) <=> (b.id || 999_999)
      end
    end
  end
end
