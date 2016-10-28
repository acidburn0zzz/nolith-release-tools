require 'spec_helper'
require 'yaml'

require 'changelog/entry'

describe Changelog::Entry do
  def entry(hash)
    content = hash.to_yaml

    described_class.new('foo/bar', double(content: content))
  end

  describe 'initialize' do
    it 'parses blob content' do
      entry = entry('title' => 'Foo', 'merge_request' => 1234, 'author' => 'Joe Smith')

      aggregate_failures do
        expect(entry.title).to eq 'Foo'
        expect(entry.id).to eq 1234
        expect(entry.author).to eq 'Joe Smith'
      end
    end
  end

  describe '#to_s' do
    it 'includes the title, ending in a period' do
      entry = entry('title' => 'Foo')

      expect(entry.to_s).to eq 'Foo.'
    end

    it 'removes duplicate trailing periods' do
      entry = entry('title' => 'Foo.')

      expect(entry.to_s).to eq 'Foo.'
    end

    it 'includes the merge request reference when available' do
      entry = entry('title' => 'Foo', 'merge_request' => 1234)

      expect(entry.to_s).to eq 'Foo. !1234'
    end

    it 'includes the author when available' do
      entry = entry('title' => 'Foo', 'merge_request' => nil, 'author' => 'Joe Smith')

      expect(entry.to_s).to eq 'Foo. (Joe Smith)'
    end

    it 'includes the merge request reference and author when available' do
      entry = entry('title' => 'Foo', 'merge_request' => 1234, 'author' => 'Joe Smith')

      expect(entry.to_s).to eq 'Foo. !1234 (Joe Smith)'
    end
  end
end
