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
    # VCR: to record new requests, credentials must be filled in .env file
    let(:pkgcloud) { described_class.new }

    it 'returns a client using pre-defined connection and credentials', vcr: { cassette_name: 'packagecloud/connection' } do
      expect(pkgcloud).to receive(:connection).and_call_original
      expect(pkgcloud).to receive(:credentials).and_call_original
      expect(pkgcloud.client).to be_a(Packagecloud::Client)
    end
  end

  describe '#create_secret_repository' do
    # VCR: to record new requests, credentials must be filled in .env file
    subject { described_class.new }

    it 'creates a new repository', vcr: { cassette_name: 'packagecloud/repository' } do
      expect(subject.create_secret_repository('new-test-repository')).to be_truthy
    end

    it 'returns false when repository already exist', vcr: { cassette_name: 'packagecloud/repository' } do
      subject.create_secret_repository('new-test-repository')

      expect(subject.create_secret_repository('new-test-repository')).to be_falsey
    end
  end

  describe '#promote_packages' do
    # VCR: To setup the environment for VCR recording, make sure both the test-secret, gitlab-ce and gitlab-ee
    # repositories exists and you have sample packages in the secret one to be promoted
    # There is no easy way to automate this, but it should be a one-time thing.
    subject { described_class.new }

    it 'promotes packages to public repository', vcr: { cassette_name: 'packagecloud/promotion' } do
      expect(subject.promote_packages('test-secret')).to be_truthy
    end
  end

  describe '#public_repo_for_package' do
    subject { described_class.new }

    # CE
    let(:deb_amd64) { 'gitlab-ce_8.16.3-ce.1_amd64.deb' }
    let(:deb_armhf) { 'gitlab-ce_8.13.12-ce.0_armhf.deb' }
    let(:rpm_x86_64_el6) { 'gitlab-ce-8.16.3-ce.1.el6.x86_64.rpm' }
    let(:rpm_x86_64_el7) { 'gitlab-ce-8.13.11-ce.0.el7.x86_64.rpm' }
    let(:rpm_x86_64_sles13) { 'gitlab-ce-8.16.3-ce.1.sles13.x86_64.rpm' }
    let(:rpm_x86_64_sles42) { 'gitlab-ce-8.16.3-ce.0.sles42.x86_64.rpm' }

    # EE
    let(:deb_amd64_ee) { 'gitlab-ee_8.16.3-ee.1_amd64.deb' }
    let(:deb_armhf_ee) { 'gitlab-ee_8.13.12-ee.0_armhf.deb' }
    let(:rpm_x86_64_el6_ee) { 'gitlab-ee-8.16.3-ee.1.el6.x86_64.rpm' }
    let(:rpm_x86_64_el7_ee) { 'gitlab-ee-8.13.11-ee.0.el7.x86_64.rpm' }
    let(:rpm_x86_64_sles13_ee) { 'gitlab-ee-8.16.3-ee.1.sles13.x86_64.rpm' }
    let(:rpm_x86_64_sles42_ee) { 'gitlab-ee-8.16.3-ee.0.sles42.x86_64.rpm' }

    it 'returns gitlab-ce for CE packages' do
      aggregate_failures 'CE packages' do
        expect(subject.public_repo_for_package(deb_amd64)).to eq('gitlab-ce')
        expect(subject.public_repo_for_package(deb_armhf)).to eq('gitlab-ce')
        expect(subject.public_repo_for_package(rpm_x86_64_el6)).to eq('gitlab-ce')
        expect(subject.public_repo_for_package(rpm_x86_64_el7)).to eq('gitlab-ce')
        expect(subject.public_repo_for_package(rpm_x86_64_sles13)).to eq('gitlab-ce')
        expect(subject.public_repo_for_package(rpm_x86_64_sles42)).to eq('gitlab-ce')
      end
    end

    it 'returns gitlab-ee for EE packages' do
      aggregate_failures 'EE packages' do
        expect(subject.public_repo_for_package(deb_amd64_ee)).to eq('gitlab-ee')
        expect(subject.public_repo_for_package(deb_armhf_ee)).to eq('gitlab-ee')
        expect(subject.public_repo_for_package(rpm_x86_64_el6_ee)).to eq('gitlab-ee')
        expect(subject.public_repo_for_package(rpm_x86_64_el7_ee)).to eq('gitlab-ee')
        expect(subject.public_repo_for_package(rpm_x86_64_sles13_ee)).to eq('gitlab-ee')
        expect(subject.public_repo_for_package(rpm_x86_64_sles42_ee)).to eq('gitlab-ee')
      end
    end
  end
end
