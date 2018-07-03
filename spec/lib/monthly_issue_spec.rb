require 'spec_helper'

require 'monthly_issue'
require 'version'

describe MonthlyIssue do
  it_behaves_like 'issuable #initialize'

  describe '#title' do
    it "returns the issue title" do
      issue = described_class.new(version: Version.new('8.3.5-rc1'))

      expect(issue.title).to eq 'Release 8.3'
    end
  end

  describe '#description' do
    it "includes stable branch names" do
      issue = described_class.new(version: Version.new('8.3.0-rc1'))

      content = issue.description

      expect(content).to include('`8-3-stable`')
      expect(content).to include('`8-3-stable-ee`')
    end

    it "includes the version number" do
      issue = described_class.new(version: Version.new('8.3.0'))

      content = issue.description

      expect(content).to include("Tag the `8.3.0` version")
    end

    it "includes the slack channel" do
      issue = described_class.new(version: Version.new('8.3.0'))

      content = issue.description

      expect(content).to include('`#f_release_8_3`')
    end
  end

  describe '#labels' do
    it 'returns a list of labels' do
      issue = described_class.new(version: double)

      expect(issue.labels).to eq 'Release'
    end
  end
end
