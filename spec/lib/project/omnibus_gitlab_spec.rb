require 'spec_helper'
require 'project/omnibus_gitlab'

describe Project::OmnibusGitlab do
  it_behaves_like 'project #remotes'

  describe '.path' do
    it { expect(described_class.path).to eq 'gitlab-org/omnibus-gitlab' }
  end
end
