# frozen_string_literal: true

require 'spec_helper'
require 'pry'

describe ReleaseTools::GemfileParser do
  describe '#gem_version' do
    let(:fixture) { VersionFixture.new }
    let(:lockfile) { "#{fixture.fixture_path}/Gemfile.lock" }

    it 'raises a LockfileNotFoundError' do
      expect do
        described_class.new('/foobar.lock')
      end.to raise_error(ReleaseTools::GemfileParser::LockfileNotFoundError)
    end

    describe '#gem_version' do
      subject(:service) { described_class.new(lockfile) }

      context 'when the Gemfile.lock contains the version we are looking for' do
        it 'returns the version' do
          expect(
            service.gem_version('mail_room')
          ).to eq('0.9.1')
        end
      end

      context 'when the Gemfile.lock does not contain the version we are looking for' do
        it 'raises a VersionNotFoundError' do
          expect do
            service.gem_version('foobar')
          end.to raise_error(ReleaseTools::GemfileParser::VersionNotFoundError)
        end
      end
    end
  end
end
