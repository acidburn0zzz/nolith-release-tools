require 'yaml'

module Changelog
  class Entry
    # Instantiate a new Entry from a YAML String
    def self.from_yaml(yaml)
      entry = YAML.load(yaml)

      new(entry['title'], entry['id'], entry['author'])
    end

    attr_reader :title, :id, :author

    def initialize(title, id = nil, author = nil)
      @title  = title
      @id     = id
      @author = author
    end

    def to_s
      str = ""
      str << "#{title}.".gsub(/\.{2,}$/, '.')
      str << " !#{id}" if id
      str << " (#{author})" if author

      str
    end
  end
end
