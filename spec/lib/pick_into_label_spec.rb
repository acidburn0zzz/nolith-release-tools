require 'spec_helper'

require 'pick_into_label'

describe PickIntoLabel do
  describe '.for' do
    it 'returns the correct label' do
      version = instance_double('Version', to_minor: 'foo')

      expect(described_class.for(version)).to eq '~"Pick into foo"'
    end
  end
end
