require 'spec_helper'

require 'version'

describe Version do
  def version(version_string)
    described_class.new(version_string)
  end

  describe '#==' do
    it { expect(version('1.2.3') == version('1.2.3-ee')).to be_truthy }
    it { expect(version('1.2.3-rc1') == version('1.2.3-rc1-ee')).to be_truthy }
  end

  describe '#<=>' do
    it { expect(version('1.2.3')).to be >= version('1.2.2') }
    it { expect(version('1.2.3')).to be > version('1.2.2') }
    it { expect(version('1.2.3')).to be > version('1.1.12') }
    it { expect(version('1.2.3')).to be > version('0.12.12') }
    it { expect(version('1.2.3')).to be > version('1.2.3-rc') }
    it { expect(version('1.2.3')).to be > version('1.2.3-rc2') }
    it { expect(version('1.2.3-rc3')).to be > version('1.2.3-rc1') }

    it { expect(version('1.2.3-rc1')).to be < version('1.2.3-rc3') }
    it { expect(version('1.2.3')).to be < version('1.2.4-rc') }
    it { expect(version('1.2.3')).to be < version('1.2.4') }
    it { expect(version('1.2.3')).to be < version('1.3.0') }
    it { expect(version('1.2.3')).to be < version('2.0.8') }
    it { expect(version('1.2.3')).to be <= version('2.0.8') }
  end

  describe '#milestone_name' do
    it 'returns the milestone name' do
      expect(version('8.3.2').milestone_name).to eq '8.3'
    end
  end

  describe '#ee?' do
    it 'returns true when EE' do
      expect(version('8.3.2-ee')).to be_ee
    end

    it 'returns false when not EE' do
      expect(version('8.3.2')).not_to be_ee
    end
  end

  describe '#milestone_name' do
    it 'returns the milestone name' do
      expect(version('8.3.2').milestone_name).to eq '8.3'
    end
  end

  describe '#major' do
    it { expect(version('1.2.3').major).to eq(1) }
    it { expect(version('1.2.0-rc1').major).to eq(1) }
    it { expect(version('1.2.0-ee').major).to eq(1) }
    it { expect(version('wow.1').major).to eq(0) }
  end

  describe '#minor' do
    it { expect(version('1.2.3').minor).to eq(2) }
    it { expect(version('1.2.0-rc1').minor).to eq(2) }
    it { expect(version('1.2.0-ee').minor).to eq(2) }
    it { expect(version('wow.1').minor).to eq(0) }
  end

  describe '#patch?' do
    it 'is true for patch releases' do
      expect(version('1.2.3').patch?).to be_truthy
    end

    it 'is false for pre-releases' do
      expect(version('1.2.0-rc1').patch?).to be_falsey
    end

    it 'is false for minor releases' do
      expect(version('1.2.0').patch?).to be_falsey
    end

    it 'is false for invalid releases' do
      expect(version('wow.1').patch?).to be_falsey
    end
  end

  describe '#rc' do
    it { expect(version('1.2.3-rc').rc).to eq(0) }
    it { expect(version('1.2.3-rc1').rc).to eq(1) }
    it { expect(version('1.2.3').rc).to be_nil }
    it { expect(version('wow-rc1').rc).to be_nil }
  end

  describe '#rc?' do
    it { expect(version('1.2.3-rc')).to be_rc }
    it { expect(version('1.2.3-rc1')).to be_rc }
    it { expect(version('1.2.3')).not_to be_rc }
    it { expect(version('wow-rc1')).not_to be_rc }
  end

  describe '#release?' do
    it 'is true for release versions' do
      expect(version('1.2.3').release?).to be_truthy
    end

    it 'is false for pre-release versions' do
      expect(version('1.2.3-rc1').release?).to be_falsey
    end

    it 'is false for invalid versions' do
      expect(version('wow.1').release?).to be_falsey
    end
  end

  describe '#next_minor' do
    it 'returns next minor version' do
      expect(version('1.2.0').next_minor).to eq '1.3.0'
    end

    it 'returns next minor version when patch version is omitted' do
      expect(version('1.2').next_minor).to eq '1.3.0'
    end

    it 'returns next minor version when version is not a release' do
      expect(version('1.2.3-rc1').next_minor).to eq '1.3.0'
    end

    it 'returns next minor version when version is EE' do
      expect(version('1.2.3-ee').next_minor).to eq '1.3.0'
    end

    it 'returns next minor version when patch is > 0' do
      expect(version('1.2.3').next_minor).to eq '1.3.0'
    end
  end

  describe '#previous_patch' do
    it 'returns nil when patch is missing' do
      expect(version('1.2').previous_patch).to be_nil
    end

    it 'returns nil when version is not a release' do
      expect(version('1.2.3-rc1').previous_patch).to eq '1.2.2'
    end

    it 'returns nil when version is EE' do
      expect(version('1.2.3-ee').previous_patch).to eq '1.2.2-ee'
    end

    it 'returns previous patch when patch is 0' do
      expect(version('1.2.0').previous_patch).to be_nil
    end

    it 'returns previous patch when patch is > 0' do
      expect(version('1.2.3').previous_patch).to eq '1.2.2'
    end
  end

  describe '#next_patch' do
    it 'returns nil when patch is missing' do
      expect(version('1.2').next_patch).to eq '1.2.1'
    end

    it 'returns nil when version is not a release' do
      expect(version('1.2.3-rc1').next_patch).to eq '1.2.4'
    end

    it 'returns nil when version is EE' do
      expect(version('1.2.3-ee').next_patch).to eq '1.2.4-ee'
    end

    it 'returns next patch when patch is 0' do
      expect(version('1.2.0').next_patch).to eq '1.2.1'
    end

    it 'returns next patch when patch is > 0' do
      expect(version('1.2.3').next_patch).to eq '1.2.4'
    end
  end

  describe '#stable_branch' do
    it { expect(version('1.2.3').stable_branch).to eq '1-2-stable' }
    it { expect(version('1.23.45').stable_branch).to eq '1-23-stable' }
    it { expect(version('1.23.45-rc67').stable_branch).to eq '1-23-stable' }
    it { expect(version('1.23.45-ee').stable_branch).to eq '1-23-stable-ee' }
  end

  describe '#tag' do
    it 'returns a tag name when version is RC' do
      expect(version('1.2.3-rc1').tag).to eq 'v1.2.3-rc1'
    end

    it 'returns a tag name when patch is present' do
      expect(version('1.2.3').tag).to eq 'v1.2.3'
    end
  end

  describe '#previous_tag' do
    it 'returns nil when patch is missing' do
      expect(version('1.2').previous_tag).to be_nil
    end

    it 'returns nil when version is not a release' do
      expect(version('1.2.3-rc1').previous_tag).to be_nil
    end

    it 'returns nil when version is EE' do
      expect(version('1.2.3-ee').previous_tag).to eq 'v1.2.2-ee'
    end

    it 'returns nil when patch is 0' do
      expect(version('1.2.0').previous_tag).to be_nil
    end

    it 'returns previous tag when patch is > 0' do
      expect(version('1.2.3').previous_tag).to eq 'v1.2.2'
    end

    it 'returns previous EE tag when patch is > 0 and ee: true' do
      expect(version('1.2.3').previous_tag(ee: true)).to eq 'v1.2.2-ee'
    end
  end

  describe '#to_ce' do
    it 'returns self when already CE' do
      version = version('1.2.3')

      expect(version.to_ce).to eql version
    end

    it 'returns a CE version when EE' do
      version = version('1.2.3-ee')

      expect(version.to_ce.to_s).to eq '1.2.3'
    end
  end

  describe '#to_ee' do
    it 'returns self when already EE' do
      version = version('1.2.3-ee')

      expect(version.to_ee).to eql version
    end

    it 'returns a EE version when CE' do
      version = version('1.2.3')

      expect(version.to_ee.to_s).to eq '1.2.3-ee'
    end
  end

  describe '#to_minor' do
    it 'returns the minor version' do
      expect(version('1.23.4').to_minor).to eq '1.23'
    end
  end

  describe '#to_omnibus' do
    it 'converts pre-releases' do
      aggregate_failures do
        expect(version('1.23.4-rc1').to_omnibus).to eq '1.23.4+rc1.ce.0'

        expect(version('1.23.4-rc1').to_omnibus(ee: true)).to eq '1.23.4+rc1.ee.0'
      end
    end

    it 'converts minor releases' do
      aggregate_failures do
        expect(version('1.23.0').to_omnibus).to eq '1.23.0+ce.0'
        expect(version('1.23.0').to_omnibus(ee: true)).to eq '1.23.0+ee.0'
      end
    end

    it 'converts patch releases' do
      aggregate_failures do
        expect(version('1.23.2').to_omnibus).to eq '1.23.2+ce.0'
        expect(version('1.23.2').to_omnibus(ee: true)).to eq '1.23.2+ee.0'
      end
    end
  end

  describe '#to_docker' do
    it 'converts pre-releases' do
      aggregate_failures do
        expect(version('1.23.4-rc1').to_docker).to eq '1.23.4-rc1.ce.0'

        expect(version('1.23.4-rc1').to_docker(ee: true)).to eq '1.23.4-rc1.ee.0'
      end
    end

    it 'converts minor releases' do
      aggregate_failures do
        expect(version('1.23.0').to_docker).to eq '1.23.0-ce.0'
        expect(version('1.23.0').to_docker(ee: true)).to eq '1.23.0-ee.0'
      end
    end

    it 'converts patch releases' do
      aggregate_failures do
        expect(version('1.23.2').to_docker).to eq '1.23.2-ce.0'
        expect(version('1.23.2').to_docker(ee: true)).to eq '1.23.2-ee.0'
      end
    end
  end

  describe '#to_patch' do
    it 'returns the patch version' do
      expect(version('1.23.4-rc1').to_patch).to eq '1.23.4'
    end
  end

  describe '#to_rc' do
    it 'defaults to rc1' do
      aggregate_failures do
        expect(version('8.3.0').to_rc).to eq '8.3.0-rc1'
        expect(version('8.3.0-rc2').to_rc).to eq '8.3.0-rc1'
      end
    end

    it 'accepts an optional number' do
      expect(version('8.3.0').to_rc(3)).to eq '8.3.0-rc3'
    end
  end

  describe '#valid?' do
    it { expect(version('1.2.3').valid?).to be_truthy }
    it { expect(version('11.22.33').valid?).to be_truthy }
    it { expect(version('2.2.3-rc1').valid?).to be_truthy }
    it { expect(version('2.2.3.rc1').valid?).to be_falsey }
    it { expect(version('1.2.3.4').valid?).to be_falsey }
    it { expect(version('wow').valid?).to be_falsey }
  end
end
