require 'yaml'

module Changelog
  # Represents a Rugged::Blob and its changelog entry
  class Entry
    attr_reader :path, :blob
    attr_reader :title, :id, :author

    # path - Path to the blob, relative to the Repository root
    # blob - Underlying rugged::Blob object
    def initialize(path, blob)
      @path = path
      @blob = blob

      parse_blob(blob.content)
    end

    def to_s
      str = ""
      str << "#{title}.".gsub(/\.{2,}$/, '.')
      str << " !#{id}" if id
      str << " (#{author})" if author

      str
    end

    private

    def parse_blob(content)
      yaml = YAML.load(content)

      @title  = yaml['title']
      @id     = yaml['merge_request'] || yaml['id']
      @author = yaml['author']
    end
  end
end
