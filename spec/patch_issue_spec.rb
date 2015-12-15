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

      content = issue.description

      aggregate_failures do
        expect(content).to include '`8-3-stable`'
        expect(content).to include '`8-3-stable-ee`'
      end
    end

    it 'includes the full version' do
      issue = described_class.new(Version.new('8.3.1'))

      content = issue.description

      expect(content).to include '8.3.1'
    end

    it 'includes the Omnibus versions' do
      issue = described_class.new(Version.new('8.3.1'))

      content = issue.description

      aggregate_failures do
        expect(content).to include '`8.3.1+ee.0`'
        expect(content).to include '`8.3.1+ce.0`'
      end
    end

    it 'includes a link to the regression issue' do
      issue = described_class.new(Version.new('8.3.1'))

      content = issue.description

      expect(content).to include "Add patch notice to [](TODO)"
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
end
