require 'spec_helper'

require 'issue'

describe Issue do
  describe '#create' do
    it 'calls GitlabClient.create_issue' do
      expect(GitlabClient).to receive(:create_issue).with(subject)

      subject.create
    end
  end

  describe '#remote_issuable' do
    it 'delegates to GitlabClient' do
      expect(GitlabClient).to receive(:find_issue).with(subject)

      subject.remote_issuable
    end
  end

  describe '#confidential?' do
    it { expect(subject).not_to be_confidential }
  end

  describe '#_url' do
    it 'returns the remote_issuable url' do
      remote_issuable = double
      allow(subject).to receive(:remote_issuable).and_return(remote_issuable)

      expect(GitlabClient).to receive(:issue_url).with(remote_issuable).and_return('https://example.com/')
      expect(subject.__send__(:_url)).to eq 'https://example.com/'
    end
  end
end
