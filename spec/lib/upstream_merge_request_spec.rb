require 'spec_helper'

require 'upstream_merge_request'

describe UpstreamMergeRequest do
  describe '.open_mrs' do
    context 'when no open upstream MR exists' do
      before do
        allow(GitlabClient).to receive(:merge_requests)
          .with(Project::GitlabEe, labels: 'CE upstream', state: 'opened')
          .and_return([])
      end

      it { expect(described_class.open_mrs).to be_empty }
    end

    context 'when an open upstream MR exists' do
      let(:mr) { double(target_branch: 'master') }

      before do
        allow(GitlabClient).to receive(:merge_requests)
          .with(Project::GitlabEe, labels: 'CE upstream', state: 'opened')
          .and_return([mr])
      end

      it { expect(described_class.open_mrs).to eq([mr]) }
    end

    context 'when an open MR exists but the target_branch is not master' do
      let(:mr) { double(target_branch: '9-5-stable') }

      before do
        allow(GitlabClient).to receive(:merge_requests)
          .with(Project::GitlabEe, labels: 'CE upstream', state: 'opened')
          .and_return([mr])
      end

      it { expect(described_class.open_mrs).to be_empty }
    end
  end

  describe '#project' do
    it { expect(subject.project).to eq Project::GitlabEe }
  end

  describe '#title' do
    it { expect(subject.title).to eq "CE upstream - #{Date.today.strftime('%A')}" }
  end

  describe '#labels' do
    it { expect(subject.labels).to eq 'CE upstream' }
  end

  describe '#source_branch' do
    it { expect(subject.source_branch).to eq "ce-to-ee-#{Date.today.iso8601}" }
  end
end
