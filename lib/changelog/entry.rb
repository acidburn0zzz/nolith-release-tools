require 'yaml'
require 'active_support/core_ext/object/blank'

module Changelog
  # Represents a Rugged::Blob and its changelog entry
  class Entry
    attr_reader :path, :blob
    attr_reader :type, :title, :id, :author

    # path - Path to the blob, relative to the Repository root
    # blob - Underlying Rugged::Blob object
    def initialize(path, blob)
      @path = path
      @blob = blob

      parse_blob(blob.content)
    end

    def to_s
      str = ""
      str << "[#{type.upcase}] " if type.present?
      str << "#{title}.".gsub(/\.{2,}$/, '.')
      str << " !#{id}" if id.present?
      str << " (#{author})" if author.present?

      str
    end

    def valid?
      title.present?
    end

    private

    def parse_blob(content)
      yaml = YAML.safe_load(content)

      @type   = yaml['type']
      @title  = yaml['title']
      @id     = parse_id(yaml)
      @author = yaml['author']

      @id = @id.to_i if @id.present? # We don't want `nil` to become `0`
    rescue StandardError # rubocop:disable Lint/HandleExceptions
      # noop
    end

    def parse_id(yaml)
      id = yaml['merge_request'] || yaml['id']
      id.to_s.gsub!(/[^\d]/, '')

      id
    end
  end
end
