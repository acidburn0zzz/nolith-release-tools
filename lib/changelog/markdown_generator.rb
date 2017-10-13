require 'date'

require_relative '../release'

module Changelog
  class MarkdownGenerator
    # nil is the last type in the order
    TYPE_ORDER = ['security', 'removed', 'fixed', 'deprecated', 'changed',
                   'performance', 'added', 'other', nil].freeze

    attr_reader :version, :entries

    def initialize(version, entries)
      @version = version
      @entries = entries.select(&:valid?)
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
      if version.monthly?
        Date.today.strftime("%Y-%m-22")
      else
        Date.today.strftime("%Y-%m-%d")
      end
    end

    # Sort entries by type in TYPE_ORDER and ID in ascending order
    # invalid types are sorted last
    def sorted_entries
      grouped_entries = entries_sorted_by_id.group_by(&:type)

      TYPE_ORDER.inject([]) do |entries, type|
        entries.concat(grouped_entries.delete(type) || [])
      end.concat(grouped_entries.values.flatten)
    end

    # Sort entries in ascending order by ID
    #
    # Entries without an ID are placed last
    def entries_sorted_by_id
      entries.sort do |a, b|
        (a.id || 999_999).to_i <=> (b.id || 999_999).to_i
      end
    end
  end
end
