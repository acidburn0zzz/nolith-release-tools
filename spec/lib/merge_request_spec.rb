require 'spec_helper'

require 'merge_request'

describe MergeRequest do
  subject do
    described_class.new do |merge_request|
      merge_request.project = Project::GitlabCe
    end
  end

  describe '#create' do
    it 'calls GitlabClient.create_issue' do
      expect(GitlabClient).to receive(:create_merge_request).with(subject, Project::GitlabCe)

      subject.create
    end
  end

  describe '#remote_issuable' do
    it 'delegates to GitlabClient' do
      expect(GitlabClient).to receive(:find_merge_request).with(subject, Project::GitlabCe)

      subject.remote_issuable
    end
  end

  describe '#_url' do
    it 'returns the remote_issuable url' do
      remote_issuable = double
      allow(subject).to receive(:remote_issuable).and_return(remote_issuable)

      expect(GitlabClient).to receive(:merge_request_url).with(remote_issuable, Project::GitlabCe).and_return('https://example.com/')
      expect(subject.__send__(:url)).to eq 'https://example.com/'
    end
  end
end
