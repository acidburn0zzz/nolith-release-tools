require 'spec_helper'
require 'project/gitlab_ce'

describe Project::GitlabCe do
  it_behaves_like 'project #remotes'

  describe '.path' do
    it { expect(described_class.path).to eq 'gitlab-org/gitlab-ce' }
  end
end
