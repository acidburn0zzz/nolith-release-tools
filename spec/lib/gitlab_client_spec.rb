require 'spec_helper'

require 'gitlab_client'

describe GitlabClient do
  describe '.find_issue' do
    context 'when issue is open' do
      it 'finds issues by title', vcr: {cassette_name: 'issues/release-8-7'} do
        version = double(milestone_name: '8.7')
        issue = double(title: 'Release 8.7', labels: 'Release', version: version)

        expect(described_class.find_issue(issue)).not_to be_nil
      end
    end

    context 'when issue is closed' do
      it 'finds issues by title', vcr: {cassette_name: 'issues/regressions-8-5'} do
        version = double(milestone_name: '8.5')
        issue = double(title: '8.5 Regressions', labels: 'Release', state_filter: nil, version: version)

        expect(described_class.find_issue(issue)).not_to be_nil
      end
    end

    context 'when issue cannot be found' do
      it 'does not find non-matching issues', vcr: {cassette_name: 'issues/release-7-14'} do
        version = double(milestone_name: '7.14')
        issue = double(title: 'Release 7.14', labels: 'Release', version: version)

        expect(described_class.find_issue(issue)).to be_nil
      end
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
