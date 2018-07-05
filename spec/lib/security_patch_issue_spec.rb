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
      end
    end

    it 'includes a step to create the blog post in a private snippet' do
      issue = described_class.new(version: Version.new('8.3.1'))

      content = issue.description

      expect(content).to include 'Ping the Security Engineers so they can get started with the blog post. The blog post should also be done on https://dev.gitlab.org/ in a **private snippet'
    end

    it 'includes a step to perform a security release' do
      issue = described_class.new(version: Version.new('8.3.1'))

      content = issue.description

      expect(content).to include '/chatops run tag --security 8.3.1'
    end

    it 'includes a step to publish the packages' do
      issue = described_class.new(version: Version.new('8.3.1'))

      content = issue.description

      expect(content).to include 'From the [build pipeline], [manually publish public packages]'
    end
  end
end
