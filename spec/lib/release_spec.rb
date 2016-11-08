require 'spec_helper'
require 'release'

describe Release do
  describe '.next_date' do
    it 'defaults to the 22nd of this month' do
      Timecop.travel(Time.local(2015, 12, 1))

      expect(described_class.next_date).to eq Date.new(2015, 12, 22)
    end

    it 'uses the 22nd of next month when after the 15th' do
      Timecop.travel(Time.local(2015, 12, 15))

      expect(described_class.next_date).to eq Date.new(2016, 1, 22)
    end
  end
end
