# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::AutoDeploy::MergeRequestNotifier do
  let(:notifier) do
    described_class.new(from: 'A', to: 'B', version: 'B', environment: 'gstg')
  end

  let(:mr1) do
    double(:mr1, project_id: 1, iid: 2, web_url: 'https://gitlab.com/foo')
  end

  let(:mr2) do
    double(:mr2, project_id: 1, iid: 3, web_url: 'https://www.gitlab.com/bar')
  end

  let(:mr3) do
    double(:mr3, project_id: 1, iid: 4, web_url: 'https://dev.gitlab.org/baz')
  end

  before do
    mrs = double(:merge_requests, to_a: [mr1, mr2, mr3])

    allow(ReleaseTools::Qa::MergeRequests)
      .to receive(:new)
      .with(
        projects: ReleaseTools::Qa::PROJECTS,
        from: an_instance_of(ReleaseTools::Qa::Ref),
        to: an_instance_of(ReleaseTools::Qa::Ref)
      )
      .and_return(mrs)
  end

  describe '#notify_all' do
    it 'notifies all merge requests' do
      expect(notifier).to receive(:notify).with(mr1)
      expect(notifier).to receive(:notify).with(mr2)
      expect(notifier).not_to receive(:notify).with(mr3)

      notifier.notify_all
    end
  end

  describe '#notify' do
    context 'when a merge request is already deployed to an environment' do
      it 'does nothing' do
        allow(mr1).to receive(:labels).and_return(%w[workflow::staging])

        expect(ReleaseTools::GitlabClient)
          .not_to receive(:create_merge_request_comment)

        notifier.notify(mr1)
      end
    end

    context 'when a merge request has not yet been deployed' do
      it 'creates a merge request comment' do
        allow(mr1).to receive(:labels).and_return([])

        expect(ReleaseTools::GitlabClient)
          .to receive(:create_merge_request_comment)
          .with(1, 2, an_instance_of(String))

        notifier.notify(mr1)
      end
    end
  end

  describe '#notify?' do
    it 'returns true when using the host gitlab.com' do
      expect(notifier.notify?(mr1)).to eq(true)
    end

    it 'returns true when using the host www.gitlab.com' do
      expect(notifier.notify?(mr2)).to eq(true)
    end

    it 'returns false when using the host dev.gitlab.org' do
      expect(notifier.notify?(mr3)).to eq(false)
    end
  end
end
