require 'yaml'
require 'active_support/core_ext/object/blank'

module Changelog
  # Represents a Rugged::Blob and its changelog entry
  class Entry
    attr_reader :path, :blob
    attr_reader :title, :id, :author

    # path - Path to the blob, relative to the Repository root
    # blob - Underlying Rugged::Blob object
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

    def valid?
      title.present?
    end

    private

    def parse_blob(content)
      yaml = YAML.load(content)

      @title  = yaml['title']
      @id     = yaml['merge_request'] || yaml['id']
      @author = yaml['author']
    rescue StandardError # rubocop:disable Lint/HandleExceptions
      # noop
    end
  end
end
