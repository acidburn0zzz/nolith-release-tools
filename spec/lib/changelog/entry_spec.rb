require 'spec_helper'

require 'changelog/entry'

describe Changelog::Entry do
  describe '.from_yaml' do
    it 'instantiates an Entry' do
      yaml = {
        'title'  => 'Foo',
        'id'     => 1234,
        'author' => 'Joe Smith'
      }.to_yaml

      entry = described_class.from_yaml(yaml)

      aggregate_failures do
        expect(entry.title).to eq 'Foo'
        expect(entry.id).to eq 1234
        expect(entry.author).to eq 'Joe Smith'
      end
    end
  end

  describe '#to_s' do
    it 'includes the title, ending in a period' do
      entry = described_class.new('Foo')

      expect(entry.to_s).to eq 'Foo.'
    end

    it 'removes duplicate trailing periods' do
      entry = described_class.new('Foo.')

      expect(entry.to_s).to eq 'Foo.'
    end

    it 'includes the merge request reference when available' do
      entry = described_class.new('Foo', 1234)

      expect(entry.to_s).to eq 'Foo. !1234'
    end

    it 'includes the author when available' do
      entry = described_class.new('Foo', nil, 'Joe Smith')

      expect(entry.to_s).to eq 'Foo. (Joe Smith)'
    end

    it 'includes the merge request reference and author when available' do
      entry = described_class.new('Foo', 1234, 'Joe Smith')

      expect(entry.to_s).to eq 'Foo. !1234 (Joe Smith)'
    end
  end
end
