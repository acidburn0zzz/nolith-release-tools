require 'spec_helper'

require 'merge_request'

describe MergeRequest do
  it_behaves_like 'issuable #initialize'
  it_behaves_like 'issuable #create', :create_merge_request
  it_behaves_like 'issuable #remote_issuable', :find_merge_request
  it_behaves_like 'issuable #url'

  describe '#source_branch' do
    it 'raises if source_branch is not set' do
      expect { described_class.new.source_branch }.to raise_error(ArgumentError, 'Please set a `source_branch`!')
    end

    it 'can be set' do
      expect(described_class.new(source_branch: 'foo').source_branch).to eq('foo')
    end
  end

  describe '#target_branch' do
    it 'defaults to `master`' do
      expect(described_class.new.target_branch).to eq('master')
    end

    it 'can be set' do
      expect(described_class.new(target_branch: 'foo').target_branch).to eq('foo')
    end
  end

  describe '#created_at' do
    context 'when passed a String' do
      it 'returns a Time' do
        expect(described_class.new(created_at: '2018-01-01').created_at).to eq(Time.new(2018, 1, 1))
      end
    end

    context 'when passed a Time' do
      it 'returns a Time' do
        expect(described_class.new(created_at: Time.new(2018, 1, 1)).created_at).to eq(Time.new(2018, 1, 1))
      end
    end
  end
end
