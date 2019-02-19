require 'spec_helper'

describe ReleaseTools::CI do
  describe '.current_job_url' do
    context 'when ENV["CI_JOB_ID"] is not present' do
      around do |ex|
        # Explicitely set the variable to nil, otherwise it's present when actually run on the CI
        ClimateControl.modify CI_JOB_ID: nil do
          ex.run
        end
      end

      it 'returns nil' do
        expect(described_class.current_job_url).to be_nil
      end
    end

    context 'when ENV["CI_JOB_ID"] is present' do
      around do |ex|
        ClimateControl.modify CI_JOB_ID: '42' do
          ex.run
        end
      end

      it 'returns the current job URL' do
        expect(described_class.current_job_url).to eq("https://gitlab.com/gitlab-org/release-tools/-/jobs/42")
      end
    end
  end
end
