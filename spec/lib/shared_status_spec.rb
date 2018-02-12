require 'spec_helper'

require 'shared_status'

describe SharedStatus do
  describe '.dry_run?' do
    it 'returns true when set' do
      ClimateControl.modify(TEST: 'true') do
        expect(described_class.dry_run?).to eq(true)
      end
    end

    it 'returns false when unset' do
      ClimateControl.modify(TEST: nil) do
        expect(described_class.dry_run?).to eq(false)
      end
    end
  end
end
