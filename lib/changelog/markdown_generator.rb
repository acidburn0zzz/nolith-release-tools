require 'date'

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

      blobs.each do |blob|
        markdown.puts "- #{blob.to_entry}"
      end

      markdown.rewind

      markdown.read
    end

    private

    def header
      "## #{version.to_patch} (#{date})"
    end

    def date
      if version.patch.zero?
        # Always use the 22nd of the month for new minor releases
        format = "%Y-%m-22"
      else
        format = "%Y-%m-%d"
      end

      Date.today.strftime(format)
    end
  end
end
