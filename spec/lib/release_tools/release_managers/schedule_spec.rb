# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::ReleaseManagers::Schedule do
  let(:schedule) { described_class.new(ReleaseTools::Version.new('11.8')) }

  let(:yaml) do
    <<~YAML
      - version: '11.8'
        date: February 22nd, 2019
        manager_americas:
          - Robert Speicher
        manager_apac_emea:
          - Yorick Peterse
    YAML
  end

  describe '#ids' do
    it 'returns the IDs of the release managers' do
      allow(schedule)
        .to receive(:authorized_manager_ids)
        .and_return('Robert Speicher' => 1, 'Yorick Peterse' => 2)

      allow(schedule)
        .to receive(:release_manager_names_from_yaml)
        .and_return(['Robert Speicher', 'Yorick Peterse'])

      expect(schedule.ids).to eq([1, 2])
    end
  end

  describe '#authorized_manager_ids' do
    it 'returns a Hash mapping release manager names to their user IDs' do
      client = instance_spy(ReleaseTools::ReleaseManagers::Client)

      allow(ReleaseTools::ReleaseManagers::Client)
        .to receive(:new)
        .and_return(client)

      allow(client)
        .to receive(:members)
        .and_return([
          double(:member, name: 'Robert Speicher', id: 1),
          double(:member, name: 'Yorick Peterse', id: 2)
        ])

      expect(schedule.authorized_manager_ids)
        .to eq('Robert Speicher' => 1, 'Yorick Peterse' => 2)
    end
  end

  describe '#release_manager_names_from_yaml' do
    context 'when no release manager data is available' do
      it 'returns an empty Array' do
        allow(schedule)
          .to receive(:download_release_manager_names)
          .and_return([])

        expect { schedule.release_manager_names_from_yaml }
          .to raise_error(described_class::VersionNotFoundError)
      end
    end

    context 'when release manager data is present' do
      it 'returns the names of the release managers' do
        allow(schedule)
          .to receive(:download_release_manager_names)
          .and_return(YAML.safe_load(yaml))

        expect(schedule.release_manager_names_from_yaml)
          .to eq(['Robert Speicher', 'Yorick Peterse'])
      end
    end
  end

  describe '#download_release_manager_names' do
    context 'when the download succeeds' do
      it 'returns the release manager data' do
        response = double(:response, body: yaml)

        allow(HTTParty)
          .to receive(:get)
          .and_return(response)

        expect(schedule.download_release_manager_names.length).to eq(1)
      end
    end

    context 'when the download fails' do
      it 'returns an empty Array' do
        allow(HTTParty)
          .to receive(:get)
          .and_raise(Errno::ENOENT)

        expect(schedule.download_release_manager_names).to be_empty
      end
    end
  end
end
