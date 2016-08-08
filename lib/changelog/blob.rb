require 'changelog/entry'

module Changelog
  class Blob
    attr_reader :path, :blob

    def initialize(path, blob)
      @path = path
      @blob = blob
    end

    def to_entry
      Changelog::Entry.from_yaml(blob.content)
    end
  end
end
