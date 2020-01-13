# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Release::CNGImageRelease do
  describe '#version_string_from_gemfile' do
    context 'when the Gemfile.lock file does not exist' do
      let(:opts) { { gitlab_repo_path: '' } }
      let(:release) { described_class.new('1.1.1', opts) }

      it 'raises a VersionFileDoesNotExistError' do
        expect do
          release.version_string_from_gemfile('mail_room')
        end.to raise_error(described_class::VersionFileDoesNotExistError)
      end
    end

    context 'when the Gemfile.lock contains the version we are looking for' do
      let(:fixture) { VersionFixture.new }
      let(:opts) { { gitlab_repo_path: fixture.fixture_path } }
      let(:release) { described_class.new('1.1.1', opts) }

      it 'returns the version' do
        expect do
          release.version_string_from_gemfile('mail_room')
        end.not_to raise_error

        expect(
          release.version_string_from_gemfile('mail_room')
        ).to eq('0.9.1')
      end
    end

    context 'when the Gemfile.lock does not contain the version we are looking for' do
      let(:fixture) { VersionFixture.new }
      let(:opts) { { gitlab_repo_path: fixture.fixture_path } }
      let(:release) { described_class.new('1.1.1', opts) }

      it 'raises a VersionNotFoundError' do
        expect do
          release.version_string_from_gemfile('foobar')
        end.to raise_error(described_class::VersionNotFoundError)
      end
    end
  end
end
