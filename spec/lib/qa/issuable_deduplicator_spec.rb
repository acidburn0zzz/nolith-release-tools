require 'spec_helper'

require 'qa/issuable_deduplicator'

describe Qa::IssuableDeduplicator do
  let(:mr1) { double("mr1", id: 1) }
  let(:mr2) { double("mr2", id: 2) }
  let(:mr3) { double("mr3", id: 1) }
  let(:merge_requests) { [mr1, mr2, mr3] }

  subject { described_class.new(merge_requests) }

  describe '#execute' do
    it 'removes duplicates' do
      expect(subject.execute).to eq([mr1, mr2])
    end
  end
end
