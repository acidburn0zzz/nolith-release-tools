require 'changelog/entry'

module Changelog
  # Wraps a Rugged::Blob object in order to know the full path of the file in
  # the tree, and allows for easy conversion to an Entry object.
  class Blob
    attr_reader :path, :blob

    # path - Path to this blob's file, relative to the Repository root
    # blob - Rugged::Blob object
    def initialize(path, blob)
      @path = path
      @blob = blob
    end

    def to_entry
      Changelog::Entry.from_yaml(blob.content)
    end
  end
end
