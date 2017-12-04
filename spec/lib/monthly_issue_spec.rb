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
    it "includes the RC version" do
      issue = described_class.new(version: Version.new('8.3.0'))

      content = issue.description

      expect(content).to include('GitLab 8.3.0-rc2 is available:')
    end

    it "includes stable branch names" do
      issue = described_class.new(version: Version.new('8.3.0-rc1'))

      content = issue.description

      expect(content).to include('merge CE `8-3-stable` into EE `8-3-stable-ee`')
    end

    it "includes the version number" do
      issue = described_class.new(version: Version.new('8.3.0'))

      content = issue.description

      aggregate_failures do
        expect(content).to include("Tag the `8.3.0` version")
        expect(content).to include("Create the `8.3.0` version on https://version.gitlab.com")
        expect(content).to include("Create the first patch issue")
        expect(content).to include('bundle exec rake "patch_issue[8.3.1]"')
      end
    end

    it "includes links to specific packages" do
      issue = described_class.new(version: Version.new('8.3.0'))

      content = issue.description

      aggregate_failures do
        expect(content).to include('https://packages.gitlab.com/gitlab/unstable/packages/ubuntu/xenial/gitlab-ee_8.3.0-rc1.ee.0_amd64.deb')
        expect(content).to include('https://packages.gitlab.com/gitlab/pre-release/packages/ubuntu/xenial/gitlab-ee_8.3.0-ee.0_amd64.deb')
      end
    end
  end

  describe '#labels' do
    it 'returns a list of labels' do
      issue = described_class.new(version: double)

      expect(issue.labels).to eq 'Release'
    end
  end

  describe '#ordinal_date' do
    it "returns an ordinal date string" do
      time = Time.new(2017, 7, 18)
      issue = described_class.new(version: double, release_date: time)

      expect(issue.ordinal_date(5)).to eq '11th'
    end
  end
end
