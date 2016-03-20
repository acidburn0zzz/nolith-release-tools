require 'spec_helper'

require 'base_issue'
require 'gitlab_client'

class TestIssue < BaseIssue
  protected

  def template
    "<%= RUBY_VERSION %>"
  end
end

describe BaseIssue do
  describe '#description' do
    it "renders ERB using the defined template" do
      issue = TestIssue.new

      expect(issue.description).to eq RUBY_VERSION
    end
  end

  describe '#create' do
    it 'calls GitlabClient.create_issue' do
      issue = TestIssue.new

      expect(GitlabClient).to receive(:create_issue).with(issue)

      issue.create
    end
  end

  describe '#exists?' do
    it 'is true when issue exists' do
      issue = TestIssue.new

      allow(issue).to receive(:remote_issue).and_return(double)

      expect(issue.exists?).to be_truthy
    end

    it 'is false when issue is missing' do
      issue = TestIssue.new

      allow(issue).to receive(:remote_issue).and_return(nil)

      expect(issue.exists?).to be_falsey
    end
  end

  describe '#remote_issue' do
    it 'delegates to GitlabClient' do
      issue = TestIssue.new

      expect(GitlabClient).to receive(:find_open_issue).with(issue)

      issue.remote_issue
    end
  end

  describe '#url' do
    it 'returns a blank string when remote issue does not exist' do
      issue = TestIssue.new

      allow(issue).to receive(:remote_issue).and_return(nil)

      expect(GitlabClient).not_to receive(:issue_url)
      expect(issue.url).to eq ''
    end

    it 'returns the remote_issue url' do
      remote = double
      issue = TestIssue.new

      allow(issue).to receive(:remote_issue).and_return(remote)

      expect(GitlabClient).to receive(:issue_url).with(remote).and_return('https://example.com/')
      expect(issue.url).to eq 'https://example.com/'
    end
  end
end
