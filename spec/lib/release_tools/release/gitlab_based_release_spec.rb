# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Release::GitlabBasedRelease do
  describe '.new' do
    let(:version) { 'v1.0.0' }
    let(:options) { { gitlab_repo_path: '/tmp' } }

    subject { described_class.new(version, options) }

    it 'does not raise errors' do
      expect { subject }.not_to raise_error
    end

    context 'when the options hash has no gitlab_repo_path' do
      let(:options) { {} }

      it 'does not raise errors' do
        expect { subject }.to raise_error ArgumentError, "missing gitlab_repo_path"
      end
    end
  end
end
