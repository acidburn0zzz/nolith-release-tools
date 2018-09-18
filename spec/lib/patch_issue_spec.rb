require 'spec_helper'

require 'patch_issue'
require 'version'

describe PatchIssue do
  it_behaves_like 'issuable #initialize'

  describe '#title' do
    it 'returns the issue title' do
      issue = described_class.new(version: Version.new('8.3.1'))

      expect(issue.title).to eq 'Release 8.3.1'
    end
  end

  describe '#description' do
    it 'includes the stable branch names' do
      issue = described_class.new(version: Version.new('8.3.1'))

      content = issue.description

      aggregate_failures do
        expect(content).to include '8-3-stable-ee'
        expect(content).to include("Tag the `8.3.1` version")
      end
    end

    it 'includes the full version' do
      issue = described_class.new(version: Version.new('8.3.1'))

      content = issue.description

      expect(content).to include '8.3.1'
    end

    it 'includes the link to post deployment patches' do
      issue = described_class.new(version: Version.new('8.3.1'))

      expect(issue.description)
        .to include('https://dev.gitlab.org/gitlab/post-deployment-patches/tree/master/8.3')
    end
  end

  describe '#labels' do
    it 'returns a list of labels' do
      issue = described_class.new(version: Version.new(''))

      expect(issue.labels).to eq 'Release'
    end
  end
end
