# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReleaseTools::Services::SecurityPreparationService do
  subject(:service) { described_class.new }

  let(:versions) do
    VCR.use_cassette('versions/list') do
      ReleaseTools::VersionClient.versions.collect(&:version)
    end
  end

  describe '.next_versions' do
    it 'returns the next patch versions of the latest releases' do
      allow(service).to receive(:current_versions).and_return(versions)

      expect(service.next_versions)
        .to contain_exactly('11.7.6', '11.6.10', '11.5.11')
    end
  end
end
