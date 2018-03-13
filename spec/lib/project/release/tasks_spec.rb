require 'spec_helper'
require 'project/release/tasks'

describe Project::Release::Tasks do
  describe '.group' do
    it { expect(described_class.group).to eq 'gitlab-org/release' }
  end

  describe '.path' do
    it { expect(described_class.path).to eq 'gitlab-org/release/tasks' }
  end
end
