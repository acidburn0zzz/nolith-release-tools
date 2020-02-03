# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Release::CNGImageRelease do
  describe '#tag' do
    context 'when CE and UBI is enabled' do
      let(:opts) { { ubi: true } }
      let(:release) { described_class.new('1.1.1', opts) }

      it 'returns the CE tag' do
        expect(release.tag).to eq 'v1.1.1'
      end
    end

    context 'when EE and UBI is disabled' do
      let(:opts) { { ubi: false } }
      let(:release) { described_class.new('1.1.1-ee', opts) }

      it 'returns the EE tag' do
        expect(release.tag).to eq 'v1.1.1-ee'
      end
    end

    context 'when EE and UBI is enabled' do
      let(:opts) { { ubi: true } }
      let(:release) { described_class.new('1.1.1-ee', opts) }

      it 'returns the UBI tag' do
        expect(release.tag).to eq 'v1.1.1-ubi8'
      end
    end

    context 'when EE and UBI is enabled and UBI version is specified' do
      let(:opts) { { ubi: true, ubi_version: '7' } }
      let(:release) { described_class.new('1.1.1-ee', opts) }

      it 'returns the specified UBI tag' do
        expect(release.tag).to eq 'v1.1.1-ubi7'
      end
    end
  end
end
