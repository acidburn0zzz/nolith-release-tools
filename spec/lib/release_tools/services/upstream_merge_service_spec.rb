# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Services::UpstreamMergeService do
  let(:upstream_merge) { double(execute!: []) }

  around do |example|
    Timecop.freeze('2017-11-15 18:12 UTC') do
      example.run
    end
  end

  shared_context 'stub collaborators' do
    before do
      expect(ReleaseTools::UpstreamMergeRequest).to receive(:new)
        .with(mention_people: subject.mention_people).and_call_original

      expect(ReleaseTools::UpstreamMerge).to receive(:new)
        .with(
          origin: ReleaseTools::Project::GitlabEe.remotes[:gitlab],
          upstream: ReleaseTools::Project::GitlabCe.remotes[:gitlab],
          source_branch: 'ce-to-ee-2017-11-15'
        ).and_return(upstream_merge)
    end
  end

  shared_context 'without conflicts' do
    before do
      allow(subject.upstream_merge_request).to receive(:conflicts?).and_return(false)
    end
  end

  shared_context 'with conflicts' do
    before do
      allow(subject.upstream_merge_request).to receive(:conflicts?).and_return(true)
    end
  end

  shared_examples 'successful MR creation without automatic acceptance' do
    include_context 'stub collaborators'
    include_context 'with conflicts'

    it 'returns a successful result object' do
      expect(subject.upstream_merge_request).to receive(:create)
      expect(subject.upstream_merge_request).not_to receive(:accept)

      result = subject.perform

      expect(result).to be_success
      expect(result.payload).to eq({ upstream_mr: subject.upstream_merge_request })
    end
  end

  shared_examples 'successful MR creation and automatic acceptance' do
    include_context 'stub collaborators'
    include_context 'without conflicts'

    it 'returns a successful result object' do
      expect(subject.upstream_merge_request).to receive(:create)
      expect(subject.upstream_merge_request).to receive(:approve)
      expect(subject.upstream_merge_request).to receive(:accept)

      result = subject.perform

      expect(result).to be_success
      expect(result.payload).to eq({ upstream_mr: subject.upstream_merge_request })
    end
  end

  shared_examples 'dry-run MR creation' do
    include_context 'stub collaborators'

    it 'returns a successful result object' do
      expect(subject.upstream_merge_request).not_to receive(:create)
      expect(subject.upstream_merge_request).not_to receive(:accept)

      result = subject.perform

      expect(result).to be_success
      expect(result.payload).to eq({ upstream_mr: subject.upstream_merge_request })
    end
  end

  describe '#perform' do
    context 'when open upstream MR exists', vcr: { cassette_name: 'merge_requests/existing_upstream_mr' } do
      context 'when not forced' do
        it 'returns a non-successful result object' do
          result = subject.perform

          expect(result).not_to be_success

          in_progress_mr = result.payload[:in_progress_mr]
          expect(in_progress_mr).to be_an_instance_of(ReleaseTools::UpstreamMergeRequest)
          expect(in_progress_mr.created_at).to be_an_instance_of(Time)
          expect(in_progress_mr.url).to eq('https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/4023')
        end
      end

      context 'when forced' do
        subject { described_class.new(force: true) }

        before do
          expect(ReleaseTools::UpstreamMergeRequest).not_to receive(:open_mrs)
        end

        context 'when real run (default)' do
          it_behaves_like 'successful MR creation and automatic acceptance'
          it_behaves_like 'successful MR creation without automatic acceptance'
        end

        context 'when dry run' do
          subject { described_class.new(dry_run: true, force: true) }

          before do
            expect(ReleaseTools::UpstreamMergeRequest).not_to receive(:open_mrs)
          end

          it_behaves_like 'dry-run MR creation'
        end
      end
    end

    context 'when no upstream MR exist' do
      before do
        expect(ReleaseTools::UpstreamMergeRequest).to receive(:open_mrs).and_return([])
      end

      context 'when real run (default)' do
        it_behaves_like 'successful MR creation and automatic acceptance'
      end

      context 'when dry run' do
        subject { described_class.new(dry_run: true) }

        it_behaves_like 'dry-run MR creation'
      end

      context 'when mentioning people' do
        subject { described_class.new(mention_people: true) }

        it_behaves_like 'successful MR creation and automatic acceptance'
      end

      context 'when downstream is already up-to-date with upstream' do
        include_context 'stub collaborators'

        before do
          expect(upstream_merge).to receive(:execute!).and_raise(ReleaseTools::UpstreamMerge::DownstreamAlreadyUpToDate)
        end

        it 'returns a non-successful result object' do
          result = subject.perform

          expect(result).not_to be_success
          expect(result.payload[:already_up_to_date]).to be(true)
        end
      end
    end
  end
end
