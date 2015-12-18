require 'spec_helper'

require 'client'

describe Client do
  describe '.find_open_issue' do
    it 'finds issues by name', vcr: {cassette_name: 'issues/release-8-3'} do
      issue = double(title: 'Release 8.3', labels: 'release')

      expect(described_class.find_open_issue(issue)).not_to be_nil
    end

    it 'does not find non-matching issues', vcr: {cassette_name: 'issues/release-8-3'} do
      issue = double(title: 'Release 7.14', labels: 'release')

      expect(described_class.find_open_issue(issue)).to be_nil
    end
  end

  describe '.issue_url' do
    it 'returns the full URL to the issue' do
      issue = double(iid: 1234)

      expect(described_class.issue_url(issue)).
        to eq "https://gitlab.com/gitlab-org/gitlab-ce/issues/1234"
    end
  end
end
