# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::PickIntoLabel do
  describe '.create' do
    it 'creates a group label for the specified version' do
      version = ReleaseTools::Version.new('11.8.0-rc1')

      expect(ReleaseTools::GitlabClient).to receive(:create_group_label).with(
        'gitlab-org',
        'Pick into 11.8',
        described_class::COLOR,
        description: described_class::DESCRIPTION % '11-8-stable'
      )

      described_class.create(version)
    end
  end

  describe '.escaped' do
    it 'returns the correct label' do
      version = instance_double('Version', to_minor: 'foo')

      expect(described_class.escaped(version)).to eq "Pick+into+foo"
    end
  end

  describe '.reference' do
    it 'returns the correct label' do
      version = instance_double('Version', to_minor: 'foo')

      expect(described_class.reference(version)).to eq '~"Pick into foo"'
    end
  end
end
