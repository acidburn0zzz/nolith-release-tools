require 'spec_helper'

describe Packages::PublishService do
  describe '#execute' do
    context 'when no pipeline exists', vcr: { cassette_name: 'packages/no_pipeline' }  do
      let(:version) { Version.new('83.7.2') }

      it 'raises PipelineNotFoundError' do
        service = described_class.new(version)

        expect { service.execute }
          .to raise_error(described_class::PipelineNotFoundError)
      end
    end

    context 'when one pipeline exists' do
      # EE: https://dev.gitlab.org/gitlab/omnibus-gitlab/pipelines/86357
      # CE: https://dev.gitlab.org/gitlab/omnibus-gitlab/pipelines/86362
      context 'and there are manual jobs', vcr: { cassette_name: 'packages/pending' } do
        let(:version) { Version.new('11.1.0-rc5') }

        it 'plays all jobs in a release stage' do
          service = described_class.new(version)

          allow(GitlabDevClient).to receive(:pipelines).and_call_original
          allow(GitlabDevClient).to receive(:pipeline_jobs).and_call_original

          # CE and EE for this version each have 14 release jobs
          expect(GitlabDevClient).to receive(:job_play).exactly(14 * 2).times

          service.execute
        end
      end

      # EE: https://dev.gitlab.org/gitlab/omnibus-gitlab/pipelines/86189
      # CE: https://dev.gitlab.org/gitlab/omnibus-gitlab/pipelines/86193
      context 'and there are no manual jobs', vcr: { cassette_name: 'packages/released' } do
        let(:version) { Version.new('11.1.0-rc4') }

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
