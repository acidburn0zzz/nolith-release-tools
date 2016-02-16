require 'spec_helper'

require 'patch_issue'
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

      expect(issue.labels).to eq 'Release'
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
