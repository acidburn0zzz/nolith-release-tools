require 'spec_helper'

require 'security_patch_issue'
require 'version'

describe SecurityPatchIssue do
  it_behaves_like 'issuable #initialize'

  describe '#confidential?' do
    it 'is always confidential' do
      issue = described_class.new(version: Version.new(''))

      expect(issue).to be_confidential
    end
  end

  describe '#labels' do
    it 'includes the "security" label' do
      issue = described_class.new(version: Version.new(''))

      expect(issue.labels).to eq 'Release,security'
    end
  end

  describe '#description' do
    it 'includes steps to push to dev only' do
      issue = described_class.new(version: Version.new('8.3.1-rc2'))

      content = issue.description

      aggregate_failures do
        expect(content).to include '**Push `ce/8-3-stable` to `dev` only: `git push dev 8-3-stable`**'
        expect(content).to include '**Push `ee/8-3-stable-ee` to `dev` only: `git push dev 8-3-stable-ee`**'
        expect(content).to include '**Push `omnibus-gitlab/8-3-stable` to `dev` only: `git push dev 8-3-stable`**'
        expect(content).to include '**Push `omnibus-gitlab/8-3-stable-ee` to `dev` only: `git push dev 8-3-stable-ee`**'
        expect(content).to include "I'm going to deploy `8.3.1-rc2` to staging"
        expect(content).to include "I'm going to deploy `8.3.1-rc2` to production"
      end
    end

    it 'includes a step to create the blog post in a private snippet' do
      issue = described_class.new(version: Version.new('8.3.1'))

      content = issue.description

      expect(content).to include 'While waiting for tests to be green, now is a good time to start on [the blog post], **in a private snippet**: BLOG_POST_SNIPPET'
    end

    it 'includes a step to perform a security release' do
      issue = described_class.new(version: Version.new('8.3.1'))

      content = issue.description

      expect(content).to include 'SECURITY=true bundle exec rake "release[8.3.1]"'
    end

    it 'includes a step to redact sensitive information from confidential security issues' do
      issue = described_class.new(version: Version.new('8.3.1'))

      content = issue.description

      expect(content).to include 'Check any sensitive information from the confidential security issues, and redact them if needed'
    end

    it 'includes a step to make the confidential security issues public' do
      issue = described_class.new(version: Version.new('8.3.1'))

      content = issue.description

      expect(content).to include 'Make the confidential security issues public'
    end

    it 'includes a step to publish the packages one tag at a time' do
      issue = described_class.new(version: Version.new('8.3.1'))

      content = issue.description

      expect(content).to include 'Manually [publish the packages], one tag at a time to prevent 504 errors on our packages server.'
    end
  end
end
