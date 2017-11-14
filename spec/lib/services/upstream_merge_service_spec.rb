require 'spec_helper'

require 'services/upstream_merge_service'

describe Services::UpstreamMergeService do
  around do |example|
    Timecop.freeze do
      example.run
    end
  end

  shared_examples 'successful MR creation' do
    let(:options) { {} }
    let(:calls_create) { true }
    let(:upstream_mr) do
      double(
        source_branch: 'ce-to-ee',
        'conflicts=': nil,
        title: 'Upstream MR',
        url: 'http://foo.bar')
    end

    before do
      allow(subject).to receive(:check_for_open_upstream_mrs!).and_return(true)
      expect(UpstreamMergeRequest).to receive(:new)
        .with(
          mention_people: options.fetch(:mention_people, false)
        ).and_return(upstream_mr)
      expect(UpstreamMerge).to receive(:new)
        .with(
          origin: Project::GitlabEe.remotes[:gitlab],
          upstream: Project::GitlabCe.remotes[:gitlab],
          merge_branch: 'ce-to-ee'
        ).and_return(double(execute: []))
    end

    it 'returns a successful result object' do
      if calls_create
        expect(upstream_mr).to receive(:create)
      else
        expect(upstream_mr).not_to receive(:create)
      end

      result = subject.perform(options)

      expect(result).to be_success
      expect(result.payload).to eq({ upstream_mr: upstream_mr })
    end
  end

  describe '#perform' do
    context 'when open upstream MR exists' do
      context 'when not forced' do
        before do
          expect(UpstreamMergeRequest).to receive(:open_mrs).and_return([double(web_url: 'http://foo.bar')])
        end

        it 'returns a non-successful result object' do
          result = subject.perform

          expect(result).not_to be_success
          expect(result.payload).to eq({ in_progress_mr_url: 'http://foo.bar' })
        end
      end

      context 'when forced' do
        before do
          expect(UpstreamMergeRequest).not_to receive(:open_mrs)
        end

        it_behaves_like 'successful MR creation' do
          let(:options) { { force: true } }
        end
      end
    end

    context 'when no upstream MR exist' do
      context 'when real run (default)' do
        it_behaves_like 'successful MR creation'
      end

      context 'when dry run' do
        it_behaves_like 'successful MR creation' do
          let(:calls_create) { false }
          let(:options) { { dry_run: true } }
        end
      end

      context 'when mentioning people' do
        it_behaves_like 'successful MR creation' do
          let(:options) { { mention_people: true } }
        end
      end
    end
  end
end
