require 'spec_helper'
require 'packagecloud_client'

describe PackagecloudClient do
  include StubENV
  subject { described_class.new('user', 'token') }

  describe '#initialize' do
    context 'with all optional params' do
      it 'defines user and token during instantiation' do
        expect(subject.username).to eq('user')
        expect(subject.token).to eq('token')
      end
    end

    context 'without any param' do
      subject { described_class.new }
      before do
        stub_env('PACKAGECLOUD_USER', 'pkguser')
        stub_env('PACKAGECLOUD_TOKEN', 'pkgtoken')
      end

      it 'gets user and token from ENV variables' do
        expect(subject.username).to eq('pkguser')
        expect(subject.token).to eq('pkgtoken')
      end
    end
  end

  describe '#credentials' do
    it 'returns a credential with previously defined user and token' do
      expect(subject.credentials).to be_a(Packagecloud::Credentials)
      expect(subject.credentials.username).to eq('user')
      expect(subject.credentials.token).to eq('token')
    end
  end

  describe '#connection' do
    it 'returns a connection pointing to our instance' do
      expect(subject.connection).to be_a(Packagecloud::Connection)
      expect(subject.connection.host).to eq('packages.gitlab.com')
    end
  end

  describe '#client' do
    let(:pkgcloud) { described_class.new }

    it 'returns a client using pre-defined connection and credentials', vcr: { cassette_name: 'packagecloud/connection' } do
      expect(pkgcloud).to receive(:connection).and_call_original
      expect(pkgcloud).to receive(:credentials).and_call_original
      expect(pkgcloud.client).to be_a(Packagecloud::Client)
    end
  end

  describe '#create_secret_repository' do
    subject { described_class.new }

    it 'creates a new repository', vcr: { cassette_name: 'packagecloud/repository' } do
      expect(subject.create_secret_repository('new-test-repository')).to be_truthy
    end

    it 'returns false when repository already exist', vcr: { cassette_name: 'packagecloud/repository' } do
      subject.create_secret_repository('new-test-repository')

      expect(subject.create_secret_repository('new-test-repository')).to be_falsey
    end
  end
end
