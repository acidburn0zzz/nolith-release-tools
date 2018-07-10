require 'spec_helper'
require 'project/omnibus_gitlab'

describe Project::OmnibusGitlab do
  it_behaves_like 'project #remotes'

  describe '.path' do
    it { expect(described_class.path).to eq 'gitlab-org/omnibus-gitlab' }
  end

  describe '.dev_path' do
    it { expect(described_class.dev_path).to eq 'gitlab/omnibus-gitlab' }
  end

  describe '.group' do
    it { expect(described_class.group).to eq 'gitlab-org' }
  end

  describe '.dev_group' do
    it { expect(described_class.dev_group).to eq 'gitlab' }
  end
end
