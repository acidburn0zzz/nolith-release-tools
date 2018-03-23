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

    it "includes links to specific packages" do
      issue = described_class.new(version: Version.new('8.3.0'))

      content = issue.description

      expect(content).to include('https://packages.gitlab.com/gitlab/pre-release/packages/ubuntu/xenial/gitlab-ee_8.3.0-ee.0_amd64.deb')
    end
  end

  describe '#labels' do
    it 'returns a list of labels' do
      issue = described_class.new(version: double)

      expect(issue.labels).to eq 'Release'
    end
  end
end
