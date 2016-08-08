require 'spec_helper'

require 'changelog/blob'
require 'yaml'

describe Changelog::Blob do
  describe '#to_entry' do
    it 'returns an Entry object' do
      fake_blob = double(content: { foo: :foo }.to_yaml)
      blob = described_class.new('path', fake_blob)

      expect(blob.to_entry).to be_kind_of(Changelog::Entry)
    end

    it "instantiates an Entry with the blob's content" do
      fake_blob = double(content: 'blob content')
      blob = described_class.new('path', fake_blob)

      expect(Changelog::Entry).to receive(:from_yaml).with('blob content')

      blob.to_entry
    end
  end
end
