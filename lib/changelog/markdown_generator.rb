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
        entries.each do |entry|
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
  end
end
