require 'spec_helper'
require_relative '../lib/version'

describe Version do
  describe '.valid?' do
    it { expect(Version.valid?('1.2.3')).to be_truthy }
    it { expect(Version.valid?('11.22.33')).to be_truthy }
    it { expect(Version.valid?('2.2.3.rc1')).to be_truthy }
    it { expect(Version.valid?('1.2.3.4')).to be_falsey }
    it { expect(Version.valid?('wow')).to be_falsey }
  end

  describe '.branch_name' do
    it { expect(Version.branch_name('1.2.3')).to eq '1-2-stable' }
    it { expect(Version.branch_name('1.23.45')).to eq '1-23-stable' }
    it { expect(Version.branch_name('1.23.45.rc67')).to eq '1-23-stable' }
  end

  end
end
