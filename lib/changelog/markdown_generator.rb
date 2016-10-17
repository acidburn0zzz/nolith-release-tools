require 'date'
require 'release'

module Changelog
  class MarkdownGenerator
    attr_reader :version, :blobs

    def initialize(version, blobs)
      @version = version
      @blobs   = blobs
    end

    def to_s
      markdown = StringIO.new
      markdown.puts header
      markdown.puts

      if blobs.empty?
        markdown.puts "- No changes."
      else
        blobs.each do |blob|
          markdown.puts "- #{blob.to_entry}"
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
