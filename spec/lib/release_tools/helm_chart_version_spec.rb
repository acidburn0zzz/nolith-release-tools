require 'spec_helper'

describe ReleaseTools::HelmChartVersion do
  def version(version_string)
    described_class.new(version_string)
  end

  describe '#valid?' do
    it { expect(version('1.2.3')).to be_valid }
    it { expect(version('11.22.33')).to be_valid }
    it { expect(version('2.2.3-ee')).not_to be_valid }
    it { expect(version('2.2.3-rc1')).not_to be_valid }
    it { expect(version('2.2.3.rc1')).not_to be_valid }
    it { expect(version('1.2.3.4')).not_to be_valid }
    it { expect(version('wow')).not_to be_valid }
  end

  describe '#tag' do
    it { expect(version('1.2.3').tag).to eq('v1.2.3') }
  end
end
