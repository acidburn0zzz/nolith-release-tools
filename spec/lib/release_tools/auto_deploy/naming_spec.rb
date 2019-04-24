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

      ee_ref = SecureRandom.hex(20)
      ob_ref = SecureRandom.hex(20)

      with_pipeline('1234') do
        expect(described_class.tag(ee_ref: ee_ref, omnibus_ref: ob_ref))
          .to eq("4.2.1234+#{ee_ref[0...11]}.#{ob_ref[0...11]}")
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
