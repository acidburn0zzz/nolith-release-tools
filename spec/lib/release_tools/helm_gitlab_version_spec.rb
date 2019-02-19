require 'spec_helper'

describe ReleaseTools::HelmGitlabVersion do
  def version(version_string)
    described_class.new(version_string)
  end

  describe 'diff' do
    it { expect(version('1.2.3').diff(version('1.2.2'))).to eq :patch }
    it { expect(version('1.2.3').diff(version('1.1.12'))).to eq :minor }
    it { expect(version('1.2.3').diff(version('0.12.12'))).to eq :major }
    it { expect(version('1.2.3').diff(version('1.2.3-rc'))).to eq :rc }
    it { expect(version('1.2.3').diff(version('1.2.3-rc2'))).to eq :rc }
    it { expect(version('1.2.3-rc3').diff(version('1.2.3-rc1'))).to eq :rc }

    it { expect(version('1.2.3-rc1').diff(version('1.2.3-rc3'))).to eq :rc }
    it { expect(version('1.2.3').diff(version('1.2.4-rc'))).to eq :patch }
    it { expect(version('1.2.3').diff(version('1.2.4'))).to eq :patch }
    it { expect(version('1.2.3').diff(version('1.3.8'))).to eq :minor }
    it { expect(version('1.2.3').diff(version('2.0.8'))).to eq :major }
  end
end
