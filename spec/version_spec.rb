require 'spec_helper'
require_relative '../lib/version'

describe Version do
  describe '.branch_name' do
    it { expect(described_class.branch_name('1.2.3')).to eq '1-2-stable' }
    it { expect(described_class.branch_name('1.23.45')).to eq '1-23-stable' }
    it { expect(described_class.branch_name('1.23.45.rc67')).to eq '1-23-stable' }
    it { expect(described_class.branch_name('1.23.45-ee')).to eq '1-23-stable-ee' }
  end

  describe '.patch?' do
    it 'is true for patch releases' do
      expect(described_class.patch?('1.2.3')).to be_truthy
    end

    it 'is false for pre-releases' do
      expect(described_class.patch?('1.2.0.rc1')).to be_falsey
    end

    it 'is false for minor releases' do
      expect(described_class.patch?('1.2.0')).to be_falsey
    end

    it 'is false for invalid releases' do
      expect(described_class.patch?('wow.1')).to be_falsey
    end
  end

  describe '.rc?' do
    it 'is true for pre-release versions' do
      expect(described_class.rc?('1.2.3.rc1')).to be_truthy
    end

    it 'is false for release versions' do
      expect(described_class.rc?('1.2.3')).to be_falsey
    end

    it 'is false for invalid versions' do
      expect(described_class.rc?('wow.rc1')).to be_falsey
    end
  end

  describe '.release?' do
    it 'is true for release versions' do
      expect(described_class.release?('1.2.3')).to be_truthy
    end

    it 'is false for pre-release versions' do
      expect(described_class.release?('1.2.3.rc1')).to be_falsey
    end

    it 'is false for invalid versions' do
      expect(described_class.release?('wow.1')).to be_falsey
    end
  end

  describe '.tag' do
    it 'returns a tag name' do
      expect(described_class.tag('1.2.3.rc1')).to eq 'v1.2.3.rc1'
      expect(described_class.tag('1.2.3')).to eq 'v1.2.3'
    end
  end

  describe '.to_minor' do
    it 'returns the minor version' do
      expect(described_class.to_minor('1.23.4')).to eq '1.23'
    end
  end

  describe '.to_patch' do
    it 'returns the patch version' do
      expect(described_class.to_patch('1.23.4.rc1')).to eq '1.23.4'
    end
  end

  describe '.valid?' do
    it { expect(described_class.valid?('1.2.3')).to be_truthy }
    it { expect(described_class.valid?('11.22.33')).to be_truthy }
    it { expect(described_class.valid?('2.2.3.rc1')).to be_truthy }
    it { expect(described_class.valid?('1.2.3.4')).to be_falsey }
    it { expect(described_class.valid?('wow')).to be_falsey }
  end
end
