require 'spec_helper'

require 'release_managers'

describe ReleaseManagers::Definitions do
  subject { described_class.new(fixture) }

  let(:fixture) { File.expand_path('../../fixtures/release_managers.yml', __dir__) }

  describe 'class delegators' do
    it 'delegates .allowed?' do
      expect(described_class).to respond_to(:allowed?)
    end

    it 'delegates .sync!' do
      expect(described_class).to respond_to(:sync!)
    end
  end

  describe '#all' do
    it 'returns an array of User objects' do
      expect(subject.all)
        .to all(be_kind_of(described_class::User))
    end

    it 'is enumerable' do
      expect(subject).to respond_to(:any?)
    end
  end

  describe '#allowed?' do
    it 'returns true for a defined user' do
      expect(subject).to be_allowed('rspeicher')
    end

    it 'returns false for an undefined user' do
      expect(subject).not_to be_allowed('invalid-member')
    end
  end

  describe '#reload!' do
    it 'raises `ArgumentError` if the config file is missing' do
      expect { described_class.new('foo.yml') }
        .to raise_error(ArgumentError, 'foo.yml does not exist!')
    end

    it 'raises `ArgumentError` if the config file is empty' do
      allow(YAML).to receive(:load_file).and_return({})

      expect { described_class.new('foo.yml') }
        .to raise_error(ArgumentError, 'foo.yml contains no data')
    end
  end

  describe '#sync!' do
    def client_spy(client_to_spy_on)
      client_spy = spy

      case client_to_spy_on
      when :dev
        allow(subject).to receive(:dev_client).and_return(client_spy)
        allow(subject).to receive(:production_client).and_return(double.as_null_object)
      else
        allow(subject).to receive(:dev_client).and_return(double.as_null_object)
        allow(subject).to receive(:production_client).and_return(client_spy)
      end

      client_spy
    end

    it 'syncs dev usernames' do
      client = client_spy(:dev)

      subject.sync!

      expect(client).to have_received(:sync_membership)
        .with(%w[james new-team-member-dev rspeicher])
    end

    it 'syncs production usernames' do
      client = client_spy(:production)

      subject.sync!

      expect(client).to have_received(:sync_membership)
        .with(%w[jameslopez new-team-member rspeicher])
    end
  end

  describe described_class::User do
    describe 'initialize' do
      it 'raises ArgumentError when no `gitlab.com` value is provided' do
        expect { described_class.new('foo', bar: :baz) }
          .to raise_error(ArgumentError, /gitlab\.com/)
      end
    end
  end
end
