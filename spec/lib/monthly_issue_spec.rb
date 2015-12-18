require 'spec_helper'

require 'monthly_issue'
require 'version'

describe MonthlyIssue do
  describe '#title' do
    it "returns the issue title" do
      issue = described_class.new(Version.new('8.3.5.rc1'))

      expect(issue.title).to eq 'Release 8.3'
    end
  end

  describe '#description' do
    it "includes ordinal date headers" do
      time = Time.new(2015, 12, 22)
      issue = described_class.new(spy, time)

      content = issue.description

      aggregate_failures do
        expect(content).to include('### 11th: (7 working days before the 22nd)')
        expect(content).to include('### 14th: (6 working days before the 22nd)')
        expect(content).to include('### 15th: (5 working days before the 22nd)')
        expect(content).to include('### 16th: (4 working days before the 22nd)')
        expect(content).to include('### 17th: (3 working days before the 22nd)')
        expect(content).to include('### 18th: (2 working days before the 22nd)')
        expect(content).to include('### 21st: (1 working day before the 22nd)')
      end
    end

    it "includes the RC version" do
      issue = described_class.new(Version.new('8.3.0'))

      content = issue.description

      expect(content).to include('GitLab 8.3.0-rc1 is available:')
    end

    it "includes stable branch names" do
      issue = described_class.new(Version.new('8.3.0.rc1'))

      content = issue.description

      expect(content).to include('Merge `8-3-stable` into `8-3-stable-ee`')
    end

    it "includes the version number" do
      issue = described_class.new(Version.new('8.3.0'))

      content = issue.description

      aggregate_failures do
        expect(content).to include("Create the '8.3.0' tag")
        expect(content).to include("Create the '8.3.0' version")
      end
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

  describe '#ordinal_date' do
    it "returns an ordinal date string" do
      time = Time.new(2015, 12, 22)
      issue = described_class.new(double, time)

      expect(issue.ordinal_date(5)).to eq '15th'
    end
  end
end
