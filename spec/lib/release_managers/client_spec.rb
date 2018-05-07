require 'spec_helper'

require 'release_managers/client'

describe ReleaseManagers::Client do
  describe 'initialize' do
    # Disable VCR for these requests, so that we can verify them with WebMock
    # without requiring a cassette recording
    around do |ex|
      VCR.turn_off!

      ex.run

      VCR.turn_on!
    end

    it 'configures properly for dev' do
      request = stub_request(:get, %r{\Ahttps://dev\.gitlab\.org/.+})

      described_class.new(:dev).members

      expect(request).to have_been_requested
    end

    it 'configures properly for production' do
      request = stub_request(:get, %r{\Ahttps://gitlab\.com/.+})

      described_class.new(:production).members

      expect(request).to have_been_requested
    end
  end

  describe '#sync_membership', :silence_stdout do
    subject { described_class.new(:dev) }

    let(:internal_client) do
      spy(
        group_members: [
          double(username: 'james'),
          double(username: 'rspeicher')
        ]
      )
    end

    before do
      allow(subject).to receive(:client).and_return(internal_client)
    end

    it 'adds missing members, skipping existing members' do
      expect(subject).to receive(:add_member).with('DouweM')
      expect(subject).not_to receive(:add_member).with('james')
      expect(subject).not_to receive(:add_member).with('rspeicher')

      subject.sync_membership(%w[DouweM james rspeicher])
    end

    it 'removes undefined members, skipping existing members' do
      expect(subject).to receive(:remove_member).with('rspeicher')
      expect(subject).not_to receive(:remove_member).with('james')

      subject.sync_membership(%w[james])
    end
  end
end
