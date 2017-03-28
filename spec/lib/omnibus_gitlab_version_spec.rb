require 'spec_helper'

require 'version'

describe OmnibusGitLabVersion do
  def version(version_string)
    described_class.new(version_string)
  end

  describe '#tag' do
    it { expect(version('1.2.3').tag).to eq('1.2.3+ce.0') }
    it { expect(version('1.2.3-ee').tag).to eq('1.2.3+ee.0') }
    it { expect(version('1.2.0-rc1').tag).to eq('1.2.0+rc1.ce.0') }
    it { expect(version('1.2.0-rc2-ee').tag).to eq('1.2.0+rc2.ee.0') }
    it { expect(version('wow.1').tag).to eq('0.0.0+ce.0') }
  end
end
