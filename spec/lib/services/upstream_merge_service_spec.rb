require 'spec_helper'

require 'services/upstream_merge_service'

describe Services::UpstreamMergeService do
  around do |example|
    Timecop.freeze(2017, 11, 15) do
      example.run
    end
  end

  shared_context 'stub collaborators' do
    before do
      expect(UpstreamMergeRequest).to receive(:new)
        .with(mention_people: subject.mention_people).and_call_original

      expect(UpstreamMerge).to receive(:new)
        .with(
          origin: Project::GitlabEe.remotes[:gitlab],
          upstream: Project::GitlabCe.remotes[:gitlab],
          merge_branch: 'ce-to-ee-2017-11-15'
        ).and_return(double(execute: []))
    end
  end

  shared_examples 'successful MR creation' do
    include_context 'stub collaborators'

    it 'returns a successful result object' do
      expect(subject.upstream_merge_request).to receive(:create)

      result = subject.perform

      expect(result).to be_success
      expect(result.payload).to eq({ upstream_mr: subject.upstream_merge_request })
    end
  end

  shared_examples 'dry-run MR creation' do
    include_context 'stub collaborators'

    it 'returns a successful result object' do
      expect(subject.upstream_merge_request).not_to receive(:create)

      result = subject.perform

      expect(result).to be_success
      expect(result.payload).to eq({ upstream_mr: subject.upstream_merge_request })
    end
  end

  describe '#perform' do
    context 'when open upstream MR exists' do
      context 'when not forced' do
        let(:in_progress_mr) { double(web_url: 'http://foo.bar') }

        before do
          expect(UpstreamMergeRequest).to receive(:open_mrs).and_return([in_progress_mr])
        end

        it 'returns a non-successful result object' do
          result = subject.perform

          expect(result).not_to be_success
          expect(result.payload).to eq({ in_progress_mr: in_progress_mr })
        end
      end

      context 'when forced' do
        subject { described_class.new(force: true) }

        before do
          expect(UpstreamMergeRequest).not_to receive(:open_mrs)
        end

        context 'when real run (default)' do
          it_behaves_like 'successful MR creation'
        end

        context 'when dry run' do
          subject { described_class.new(dry_run: true, force: true) }

          before do
            expect(UpstreamMergeRequest).not_to receive(:open_mrs)
          end

          it_behaves_like 'dry-run MR creation'
        end
      end
    end

    context 'when no upstream MR exist' do
      before do
        expect(UpstreamMergeRequest).to receive(:open_mrs).and_return([])
      end

      context 'when real run (default)' do
        it_behaves_like 'successful MR creation'
      end

      context 'when dry run' do
        subject { described_class.new(dry_run: true) }

        it_behaves_like 'dry-run MR creation'
      end

      context 'when mentioning people' do
        subject { described_class.new(mention_people: true) }

        it_behaves_like 'successful MR creation'
      end
    end
  end
end
