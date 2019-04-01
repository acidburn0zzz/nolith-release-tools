require 'spec_helper'

describe ReleaseTools::SecurityPatchIssue do
  it_behaves_like 'issuable #initialize'

  describe '#confidential?' do
    it 'is always confidential' do
      issue = described_class.new(version: ReleaseTools::Version.new(''))

      expect(issue).to be_confidential
    end
  end

  describe '#labels' do
    it 'includes the "security" label' do
      issue = described_class.new(version: ReleaseTools::Version.new(''))

      expect(issue.labels).to eq 'Monthly Release,security'
    end
  end

  describe '#description' do
    it 'includes a step to create the blog post in a private snippet' do
      issue = described_class.new(version: ReleaseTools::Version.new('8.3.1'))

      content = issue.description

      expect(content).to include 'Ping the Security Engineers so they can get started with the blog post. The blog post should also be done on https://dev.gitlab.org/ in a **private snippet'
    end

    it 'includes a step to perform a security release' do
      issue = described_class.new(version: ReleaseTools::Version.new('8.3.1'))

      content = issue.description

      expect(content).to include '/chatops run release tag --security 8.3.1'
    end

    it 'includes a step to publish the packages' do
      issue = described_class.new(version: ReleaseTools::Version.new('8.3.1'))

      content = issue.description

      expect(content).to include '/chatops run publish 8.3.1'
    end
  end
end
