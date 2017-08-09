require 'spec_helper'

require 'merge_request'

describe MergeRequest do
  it_behaves_like 'issuable #initialize'
  it_behaves_like 'issuable #create', :create_merge_request
  it_behaves_like 'issuable #remote_issuable', :find_merge_request
  it_behaves_like 'issuable #url', :merge_request_url

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

  describe '#remove_source_branch' do
    it 'defaults to false' do
      expect(described_class.new.remove_source_branch).to be(false)
    end

    it 'can be set to true' do
      expect(described_class.new(remove_source_branch: true).remove_source_branch).to be(true)
    end
  end
end
