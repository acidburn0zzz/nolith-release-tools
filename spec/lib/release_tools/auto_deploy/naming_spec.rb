# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::AutoDeploy::Naming do
  def with_pipeline(iid)
    ClimateControl.modify(CI_PIPELINE_IID: iid) { yield }
  end

  describe 'initialize' do
    it 'fails when CI_PIPELINE_IID is unset' do
      with_pipeline(nil) do
        expect { described_class.new }
          .to raise_error(/must be set in order to proceed/)
      end
    end
  end

  describe '.branch' do
    it 'returns a branch name in the appropriate format' do
      allow(ReleaseTools::GitlabClient).to receive(:current_milestone)
        .and_return(double(title: '4.2'))

      with_pipeline('1234') do
        expect(described_class.branch).to eq('4-2-auto-deploy-0001234')
      end
    end
  end

  describe '.tag' do
    it 'returns a tag name in the appropriate format' do
      allow(ReleaseTools::GitlabClient).to receive(:current_milestone)
        .and_return(double(title: '4.2'))

      args = {
        timestamp: Time.now.to_i,
        omnibus_ref: SecureRandom.hex(20),
        ee_ref: SecureRandom.hex(20)
      }

      with_pipeline('1234') do
        expect(described_class.tag(**args)).to eq(
          "4.2.#{args[:timestamp]}+#{args[:ee_ref][0...11]}.#{args[:omnibus_ref][0...11]}"
        )
      end
    end
  end

  describe '#version' do
    it 'raises an error when the milestone format is unexpected' do
      allow(ReleaseTools::GitlabClient).to receive(:current_milestone)
        .and_return(double(title: 'Backlog'))

      with_pipeline('1234') do
        expect { described_class.new.version }
          .to raise_error(/Invalid version from milestone/)
      end
    end
  end
end
