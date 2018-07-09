require 'spec_helper'

describe Packages::PublishService do
  describe '#execute' do
    it 'raises PipelineNotFoundError when no pipeline exists', vcr: { cassette_name: 'packages/no_pipeline' } do
      version = Version.new('83.7.2')
      service = described_class.new(version)

      expect { service.execute }.to raise_error(PipelineNotFoundError)
    end
  end
end
