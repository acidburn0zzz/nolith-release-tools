# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Project::Deployer do
  it_behaves_like 'project .remotes'
  it_behaves_like 'project .to_s'

  describe '.path' do
    it { expect(described_class.path).to eq 'gitlab-com/gl-infra/deployer' }
  end

  describe '.group' do
    it { expect(described_class.group).to eq 'gitlab-com/gl-infra' }
  end

  describe '.dev_path' do
    it { expect { described_class.dev_path }.to raise_error RuntimeError, 'Invalid remote for gitlab-com/gl-infra/deployer: dev' }
  end

  describe '.dev_group' do
    it { expect { described_class.dev_group }.to raise_error RuntimeError, 'Invalid remote for gitlab-com/gl-infra/deployer: dev' }
  end

  context 'during a security release' do
    before do
      enable_feature(:security_remote)

      allow(ReleaseTools::SharedStatus)
        .to receive(:security_release?)
        .and_return(true)
    end

    describe '.to_s' do
      it { expect(described_class.to_s).to eq 'gitlab-com/gl-infra/deployer' }
    end
  end
end
