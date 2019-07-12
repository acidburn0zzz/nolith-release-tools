# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Services::CNGPublishService do
  describe '#execute' do
    context 'when no pipeline exists', vcr: { cassette_name: 'services/publish_service/cng/no_pipeline' } do
      let(:version) { ReleaseTools::Version.new('83.7.2') }

      it 'raises PipelineNotFoundError' do
        service = described_class.new(version)

        expect { service.execute }
          .to raise_error(described_class::PipelineNotFoundError)
      end
    end

    context 'when one pipeline exists' do
      context 'and there are manual jobs', :silence_stdout, vcr: { cassette_name: 'services/publish_service/cng/pending' } do
        let(:version) { ReleaseTools::Version.new('12.1.0') }

        it 'plays all jobs in a release stage' do
          service = described_class.new(version)

          client = service.send(:client)
          allow(client).to receive(:pipelines).and_call_original
          allow(client).to receive(:pipeline_jobs).and_call_original

          # EE and CE each have 1 manual job
          expect(client).to receive(:job_play).twice

          without_dry_run do
            service.execute
          end
        end
      end

      context 'and there are no manual jobs', :silence_stderr, vcr: { cassette_name: 'services/publish_service/cng/released' } do
        let(:version) { ReleaseTools::Version.new('12.0.0') }

        it 'does not play any job' do
          service = described_class.new(version)

          client = service.send(:client)
          expect(client).not_to receive(:job_play)

          service.execute
        end
      end
    end
  end
end
