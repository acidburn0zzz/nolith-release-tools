require 'spec_helper'
require 'package_version'

describe PackageVersion do
  # CE
  let(:deb_amd64) { 'gitlab-ce_8.16.3-ce.1_amd64.deb' }
  let(:deb_armhf) { 'gitlab-ce_8.13.12-ce.0_armhf.deb' }
  let(:deb_rc_armhf) { 'gitlab-ce_8.13.12-rc1.ce.0_armhf.deb' }
  let(:rpm_x86_64_el6) { 'gitlab-ce-8.16.3-ce.1.el6.x86_64.rpm' }
  let(:rpm_x86_64_el7) { 'gitlab-ce-8.13.11-ce.0.el7.x86_64.rpm' }
  let(:rpm_x86_64_sles13) { 'gitlab-ce-8.16.3-ce.1.sles13.x86_64.rpm' }
  let(:rpm_x86_64_sles42) { 'gitlab-ce-8.16.3-ce.0.sles42.x86_64.rpm' }

  # EE
  let(:deb_amd64_ee) { 'gitlab-ee_8.16.3-ee.1_amd64.deb' }
  let(:deb_armhf_ee) { 'gitlab-ee_8.13.12-ee.0_armhf.deb' }
  let(:deb_rc_armhf_ee) { 'gitlab-ee_8.13.12-rc1.ee.0_armhf.deb' }
  let(:rpm_x86_64_el6_ee) { 'gitlab-ee-8.16.3-ee.1.el6.x86_64.rpm' }
  let(:rpm_x86_64_el7_ee) { 'gitlab-ee-8.13.11-ee.0.el7.x86_64.rpm' }
  let(:rpm_x86_64_sles13_ee) { 'gitlab-ee-8.16.3-ee.1.sles13.x86_64.rpm' }
  let(:rpm_x86_64_sles42_ee) { 'gitlab-ee-8.16.3-ee.0.sles42.x86_64.rpm' }

  describe '#edition' do
    context 'with community edition packages' do
      it 'returns ce for all examples' do
        aggregate_failures 'edition' do
          expect(described_class.new(deb_amd64).edition).to eq :ce
          expect(described_class.new(deb_armhf).edition).to eq :ce
          expect(described_class.new(deb_rc_armhf).edition).to eq :ce
          expect(described_class.new(rpm_x86_64_el6).edition).to eq :ce
          expect(described_class.new(rpm_x86_64_el7).edition).to eq :ce
          expect(described_class.new(rpm_x86_64_sles13).edition).to eq :ce
          expect(described_class.new(rpm_x86_64_sles42).edition).to eq :ce
        end
      end
    end

    context 'with enterprise edition packages' do
      it 'returns ee for all examples' do
        aggregate_failures 'edition' do
          expect(described_class.new(deb_amd64_ee).edition).to eq :ee
          expect(described_class.new(deb_armhf_ee).edition).to eq :ee
          expect(described_class.new(deb_rc_armhf_ee).edition).to eq :ee
          expect(described_class.new(rpm_x86_64_el6_ee).edition).to eq :ee
          expect(described_class.new(rpm_x86_64_el7_ee).edition).to eq :ee
          expect(described_class.new(rpm_x86_64_sles13_ee).edition).to eq :ee
          expect(described_class.new(rpm_x86_64_sles42_ee).edition).to eq :ee
        end
      end
    end
  end

  describe '#major' do
    it 'returns major version for all examples' do
      aggregate_failures 'major versions' do
        expect(described_class.new(deb_amd64).major).to eq 8
        expect(described_class.new(deb_armhf).major).to eq 8
        expect(described_class.new(deb_rc_armhf).major).to eq 8
        expect(described_class.new(rpm_x86_64_el6).major).to eq 8
        expect(described_class.new(rpm_x86_64_el7).major).to eq 8
        expect(described_class.new(rpm_x86_64_sles13).major).to eq 8
        expect(described_class.new(rpm_x86_64_sles42).major).to eq 8
      end
    end
  end

  describe '#minor' do
    it 'returns minor version for all examples' do
      aggregate_failures 'minor versions' do
        expect(described_class.new(deb_amd64).minor).to eq 16
        expect(described_class.new(deb_armhf).minor).to eq 13
        expect(described_class.new(deb_rc_armhf).minor).to eq 13
        expect(described_class.new(rpm_x86_64_el6).minor).to eq 16
        expect(described_class.new(rpm_x86_64_el7).minor).to eq 13
        expect(described_class.new(rpm_x86_64_sles13).minor).to eq 16
        expect(described_class.new(rpm_x86_64_sles42).minor).to eq 16
      end
    end
  end

  describe '#patch' do
    it 'returns patch version for all examples' do
      aggregate_failures 'patch versions' do
        expect(described_class.new(deb_amd64).patch).to eq 3
        expect(described_class.new(deb_armhf).patch).to eq 12
        expect(described_class.new(deb_rc_armhf).patch).to eq 12
        expect(described_class.new(rpm_x86_64_el6).patch).to eq 3
        expect(described_class.new(rpm_x86_64_el7).patch).to eq 11
        expect(described_class.new(rpm_x86_64_sles13).patch).to eq 3
        expect(described_class.new(rpm_x86_64_sles42).patch).to eq 3
      end
    end
  end

  describe "#arch" do
    it 'returns arch type for all examples' do
      aggregate_failures 'arch type' do
        expect(described_class.new(deb_amd64).arch).to eq :amd64
        expect(described_class.new(deb_armhf).arch).to eq :armhf
        expect(described_class.new(deb_rc_armhf).arch).to eq :armhf
        expect(described_class.new(rpm_x86_64_el6).arch).to eq :x86_64
        expect(described_class.new(rpm_x86_64_el7).arch).to eq :x86_64
        expect(described_class.new(rpm_x86_64_sles13).arch).to eq :x86_64
        expect(described_class.new(rpm_x86_64_sles42).arch).to eq :x86_64
      end
    end
  end

  describe "#rc" do
    it 'returns rc version when value is an RC' do
      expect(described_class.new(deb_rc_armhf).rc).to eq 1
    end
  end

  describe "#rc" do
    it 'returns nil rc version when package is not an RC' do
      aggregate_failures 'rc version' do
        expect(described_class.new(deb_amd64).rc).to eq nil
        expect(described_class.new(deb_armhf).rc).to eq nil
        expect(described_class.new(rpm_x86_64_el6).rc).to eq nil
        expect(described_class.new(rpm_x86_64_el7).rc).to eq nil
        expect(described_class.new(rpm_x86_64_sles13).rc).to eq nil
        expect(described_class.new(rpm_x86_64_sles42).rc).to eq nil
      end
    end
  end

  describe '#revision' do
    it 'returns revision version for all examples' do
      aggregate_failures 'revision versions' do
        expect(described_class.new(deb_amd64).revision).to eq 1
        expect(described_class.new(deb_armhf).revision).to eq 0
        expect(described_class.new(deb_rc_armhf).revision).to eq 0
        expect(described_class.new(rpm_x86_64_el6).revision).to eq 1
        expect(described_class.new(rpm_x86_64_el7).revision).to eq 0
        expect(described_class.new(rpm_x86_64_sles13).revision).to eq 1
        expect(described_class.new(rpm_x86_64_sles42).revision).to eq 0
      end
    end
  end

  describe '#rc?' do
    it 'returns true when is RC' do
      expect(described_class.new(deb_rc_armhf)).to be_rc
    end

    it 'returns false when not RC' do
      expect(described_class.new(deb_armhf)).not_to be_rc
    end
  end

  describe '#ee?' do
    it 'returns true when is EE' do
      expect(described_class.new(deb_amd64_ee)).to be_ee
    end

    it 'returns false when not EE' do
      expect(described_class.new(deb_amd64)).not_to be_ee
    end
  end

  describe '#ce?' do
    it 'returns false when is EE' do
      expect(described_class.new(deb_amd64_ee)).not_to be_ce
    end

    it 'returns true when not EE' do
      expect(described_class.new(deb_amd64)).to be_ce
    end
  end
end
