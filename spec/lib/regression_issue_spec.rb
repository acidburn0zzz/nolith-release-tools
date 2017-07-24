require 'spec_helper'

require 'regression_issue'
require 'version'

describe RegressionIssue do
  it_behaves_like 'issuable #initialize'

  describe '#title' do
    it 'returns the issue title' do
      issue = described_class.new(version: Version.new('8.3.1'))

      expect(issue.title).to eq '8.3 Regressions'
    end
  end

  describe '#description' do
    it 'returns the issue description' do
      issue = described_class.new(version: double)

      expect(issue.description).to include('This is a meta issue')
    end
  end

  describe '#labels' do
    it 'returns a list of labels' do
      issue = described_class.new(version: double)

      expect(issue.labels).to eq 'Release'
    end
  end
end
