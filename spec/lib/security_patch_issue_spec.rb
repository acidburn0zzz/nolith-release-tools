require 'spec_helper'

require 'security_patch_issue'
require 'version'

describe SecurityPatchIssue do
  describe '#title' do
    it 'returns the issue title' do
      issue = described_class.new(Version.new('8.3.1'))

      expect(issue.title).to eq 'Release 8.3.1'
      expect(issue).to be_confidential
    end
  end

  describe '#description' do
    it 'includes steps to push to dev only' do
      issue = described_class.new(Version.new('8.3.1'))

      allow(issue).to receive(:regression_issue).and_return(spy)
      content = issue.description

      aggregate_failures do
        expect(content).to include '**Push `ce/8-3-stable` to `dev` only: `git push dev 8-3-stable`**'
        expect(content).to include '**Push `ee/8-3-stable-ee` to `dev` only: `git push dev 8-3-stable-ee`**'
        expect(content).to include '**Push `omnibus-gitlab/8-3-stable` to `dev` only: `git push dev 8-3-stable`**'
        expect(content).to include '**Push `omnibus-gitlab/8-3-stable-ee` to `dev` only: `git push dev 8-3-stable-ee`**'
      end
    end

    it 'includes a step to create the blog post in a private snippet' do
      issue = described_class.new(Version.new('8.3.1'))

      allow(issue).to receive(:regression_issue).and_return(spy)
      content = issue.description

      expect(content).to include 'While waiting for tests to be green, now is a good time to start on [the blog post], **in a private snippet**: BLOG_POST_SNIPPET'
    end

    it 'includes a step to redact sensitive information from confidential security issues' do
      issue = described_class.new(Version.new('8.3.1'))

      allow(issue).to receive(:regression_issue).and_return(spy)
      content = issue.description

      expect(content).to include 'Check any sensitive information from the confidential security issues, and redact them if needed'
    end

    it 'includes a step to make the confidential security issues public' do
      issue = described_class.new(Version.new('8.3.1'))

      allow(issue).to receive(:regression_issue).and_return(spy)
      content = issue.description

      expect(content).to include 'Make the confidential security issues public'
    end
  end

end
