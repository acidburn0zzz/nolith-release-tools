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

  describe '#exists?' do
    it 'is true when issue exists' do
      issue = described_class.new(double)

      allow(issue).to receive(:remote_issue).and_return(double)

      expect(issue.exists?).to be_truthy
    end

    it 'is false when issue is missing' do
      issue = described_class.new(double)

      allow(issue).to receive(:remote_issue).and_return(nil)

      expect(issue.exists?).to be_falsey
    end
  end

  describe '#remote_issue' do
    it 'delegates to Client' do
      issue = described_class.new(double)

      expect(Client).to receive(:find_open_issue).with(issue)

      issue.remote_issue
    end
  end

  describe '#url' do
    it 'returns a blank string when remote issue does not exist' do
      issue = described_class.new(double)

      allow(issue).to receive(:remote_issue).and_return(nil)

      expect(Client).not_to receive(:issue_url)
      expect(issue.url).to eq ''
    end

    it 'returns the remote_issue url' do
      remote = double
      issue = described_class.new(double)

      allow(issue).to receive(:remote_issue).and_return(remote)

      expect(Client).to receive(:issue_url).with(remote).and_return('https://example.com/')
      expect(issue.url).to eq 'https://example.com/'
    end
  end
end
