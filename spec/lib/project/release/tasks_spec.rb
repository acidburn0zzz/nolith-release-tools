require 'spec_helper'
require 'project/release/tasks'

describe Project::Release::Tasks do
  it_behaves_like 'project #remotes'

  describe '.path' do
    it { expect(described_class.path).to eq 'gitlab-org/release/tasks' }
  end

  describe '.group' do
    it { expect(described_class.group).to eq 'gitlab-org/release' }
  end
end
