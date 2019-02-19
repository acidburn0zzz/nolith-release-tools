require 'spec_helper'

describe ReleaseTools::PickIntoLabel do
  describe '.escaped' do
    it 'returns the correct label' do
      version = instance_double('Version', to_minor: 'foo')

      expect(described_class.escaped(version)).to eq "Pick+into+foo"
    end
  end

  describe '.reference' do
    it 'returns the correct label' do
      version = instance_double('Version', to_minor: 'foo')

      expect(described_class.reference(version)).to eq '~"Pick into foo"'
    end
  end
end
