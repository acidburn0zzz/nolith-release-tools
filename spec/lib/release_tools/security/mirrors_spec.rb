# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Security::Mirrors do
  let(:fake_client) { spy }

  before do
    stub_const('ReleaseTools::Security::Client', fake_client)
  end

  describe '#disable' do
    it 'disables mirrors' do
      expect(subject).to receive(:update).with(enabled: false)

      subject.disable
    end
  end

  describe '#enable' do
    it 'enables mirrors' do
      expect(subject).to receive(:update).with(enabled: true)

      subject.enable
    end
  end

  describe '#update' do
    it 'does nothing without a Security mirror' do
      projects = [
        double('Project', id: 1)
      ]

      expect(subject).to receive(:canonical_projects).and_return(projects)
      expect(subject).to receive(:security_mirror)
        .with(projects.first)
        .and_return(nil)

      subject.update

      expect(fake_client).not_to have_received(:put)
    end

    it 'updates a Security mirror' do
      projects = [double('Project', id: 1).as_null_object]
      mirror = double('RemoteMirror', id: 2).as_null_object

      expect(subject).to receive(:canonical_projects).and_return(projects)
      expect(subject).to receive(:security_mirror)
        .with(projects.first)
        .and_return(mirror)

      subject.update(enabled: true)

      expect(fake_client).to have_received(:put)
        .with("/projects/1/remote_mirrors/2", hash_including(enabled: true))
    end
  end
end
