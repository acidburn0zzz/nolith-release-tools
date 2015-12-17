require 'spec_helper'

require 'regression_issue'
require 'version'

describe RegressionIssue do
  describe '#title' do
    it 'returns the issue title' do
      issue = described_class.new(Version.new('8.3.1'))

      expect(issue.title).to eq '8.3 Regressions'
    end
  end

  describe '#description' do
    it 'returns the issue description' do
      issue = described_class.new(double)

      expect(issue.description).to include('This is a meta issue')
    end
  end

  describe '#labels' do
    it 'returns a list of labels' do
      issue = described_class.new(double)

      expect(issue.labels).to eq 'regression'
    end
  end

  describe '#create' do
    it 'calls Client.create_issue' do
      issue = described_class.new(double)

      expect(Client).to receive(:create_issue).with(issue)

      issue.create
    end
  end
end
