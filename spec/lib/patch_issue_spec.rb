require 'spec_helper'

require 'patch_issue'
require 'regression_issue'
require 'version'

describe PatchIssue do
  describe '#title' do
    it 'returns the issue title' do
      issue = described_class.new(Version.new('8.3.1'))

      expect(issue.title).to eq 'Release 8.3.1'
    end
  end

  describe '#description' do
    it 'includes the stable branch names' do
      issue = described_class.new(Version.new('8.3.1'))

      allow(issue).to receive(:regression_issue).and_return(spy)
      content = issue.description

      aggregate_failures do
        expect(content).to include '`8-3-stable`'
        expect(content).to include '`8-3-stable-ee`'
      end
    end

    it 'includes the full version' do
      issue = described_class.new(Version.new('8.3.1'))

      allow(issue).to receive(:regression_issue).and_return(spy)
      content = issue.description

      expect(content).to include '8.3.1'
    end

    it 'includes the Omnibus versions' do
      issue = described_class.new(Version.new('8.3.1'))

      allow(issue).to receive(:regression_issue).and_return(spy)
      content = issue.description

      aggregate_failures do
        expect(content).to include '`8.3.1+ee.0`'
        expect(content).to include '`8.3.1+ce.0`'
      end
    end

    it 'includes a link to the regression issue' do
      issue = described_class.new(Version.new('8.3.1'))

      allow(issue).to receive(:regression_issue).
        and_return(double(title: '8.3 Regressions', url: 'https://example.com'))
      content = issue.description

      expect(content).to include "Add patch notice to [8.3 Regressions](https://example.com)"
    end
  end

  describe '#labels' do
    it 'returns a list of labels' do
      issue = described_class.new(double)

      expect(issue.labels).to eq 'release'
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

  describe '#regression_issue' do
    it 'returns a RegressionIssue object' do
      version = Version.new('8.3.1')
      issue = described_class.new(version)

      expect(RegressionIssue).to receive(:new).with(version).and_call_original
      expect(issue.regression_issue).to be_kind_of(RegressionIssue)
    end
  end
end
