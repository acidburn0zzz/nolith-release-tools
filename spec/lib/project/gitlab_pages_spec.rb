require 'spec_helper'
require 'project/gitlab_pages'

describe Project::GitlabPages do
  it_behaves_like 'project #remotes'

  describe '.path' do
    it { expect(described_class.path).to eq 'gitlab-org/gitlab-pages' }
  end
end
