require 'spec_helper'
require 'project/gitlab_ci_yml'

describe Project::GitlabCiYml do
  it_behaves_like 'project #remotes'

  describe '.path' do
    it { expect(described_class.path).to eq 'gitlab-org/gitlab-ci-yml' }
  end
end
