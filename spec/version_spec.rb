require 'spec_helper'
require_relative '../lib/version'

describe Version do
  def version(version_string)
    described_class.new(version_string)
  end

  describe '#milestone_name' do
    it 'returns the milestone name' do
      expect(version('8.3.2').milestone_name).to eq '8.3'
    end
  end

  describe '#patch?' do
    it 'is true for patch releases' do
      expect(version('1.2.3').patch?).to be_truthy
    end

    it 'is false for pre-releases' do
      expect(version('1.2.0.rc1').patch?).to be_falsey
    end

    it 'is false for minor releases' do
      expect(version('1.2.0').patch?).to be_falsey
    end

    it 'is false for invalid releases' do
      expect(version('wow.1').patch?).to be_falsey
    end
  end

  describe '#rc?' do
    it 'is true for pre-release versions' do
      aggregate_failures do
        expect(version('1.2.3.rc1').rc?).to be_truthy
        expect(version('1.2.3-rc1').rc?).to be_truthy
      end
    end

    it 'is false for release versions' do
      expect(version('1.2.3').rc?).to be_falsey
    end

    it 'is false for invalid versions' do
      expect(version('wow.rc1').rc?).to be_falsey
    end
  end

  describe '#release?' do
    it 'is true for release versions' do
      expect(version('1.2.3').release?).to be_truthy
    end

    it 'is false for pre-release versions' do
      expect(version('1.2.3.rc1').release?).to be_falsey
    end

    it 'is false for invalid versions' do
      expect(version('wow.1').release?).to be_falsey
    end
  end

  describe '#stable_branch' do
    it { expect(version('1.2.3').stable_branch).to eq '1-2-stable' }
    it { expect(version('1.23.45').stable_branch).to eq '1-23-stable' }
    it { expect(version('1.23.45.rc67').stable_branch).to eq '1-23-stable' }
    it { expect(version('1.23.45-ee').stable_branch).to eq '1-23-stable-ee' }
  end

  describe '#tag' do
    it 'returns a tag name' do
      expect(version('1.2.3.rc1').tag).to eq 'v1.2.3.rc1'
      expect(version('1.2.3').tag).to eq 'v1.2.3'
    end
  end

  describe '#to_minor' do
    it 'returns the minor version' do
      expect(version('1.23.4').to_minor).to eq '1.23'
    end
  end

  describe '#to_patch' do
    it 'returns the patch version' do
      expect(version('1.23.4.rc1').to_patch).to eq '1.23.4'
    end
  end

  describe '#to_rc' do
    it 'defaults to rc1' do
      aggregate_failures do
        expect(version('8.3.0').to_rc).to eq '8.3.0-rc1'
        expect(version('8.3.0.rc2').to_rc).to eq '8.3.0-rc1'
      end
    end

    it 'accepts an optional number' do
      expect(version('8.3.0').to_rc(3)).to eq '8.3.0-rc3'
    end
  end

  describe '#valid?' do
    it { expect(version('1.2.3').valid?).to be_truthy }
    it { expect(version('11.22.33').valid?).to be_truthy }
    it { expect(version('2.2.3.rc1').valid?).to be_truthy }
    it { expect(version('1.2.3.4').valid?).to be_falsey }
    it { expect(version('wow').valid?).to be_falsey }
  end
end
