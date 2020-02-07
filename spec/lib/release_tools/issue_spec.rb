# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Issue do
  it_behaves_like 'issuable #initialize'
  it_behaves_like 'issuable #create', :create_issue
  it_behaves_like 'issuable #remote_issuable', :find_issue
  it_behaves_like 'issuable #url'

  describe '#confidential?' do
    it { expect(subject).not_to be_confidential }
  end

  describe '#milestone_name' do
    it 'returns milestone name from version' do
      version = ReleaseTools::Version.new('12.7.4')
      issue = described_class.new(version: version)

      expect(issue.milestone_name).to eq('12.7')
    end
  end
end
