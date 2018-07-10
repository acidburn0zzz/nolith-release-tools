require 'spec_helper'
require 'project/release/tasks'

describe Project::Release::Tasks do
  it_behaves_like 'project #remotes'

  describe '.path' do
    it { expect(described_class.path).to eq 'gitlab-org/release/tasks' }
  end

  describe '.dev_path' do
    it 'raises an exception' do
      expect { described_class.dev_path }.to raise_error("Invalid remote: dev")
    end
  end

  describe '.group' do
    it { expect(described_class.group).to eq 'gitlab-org/release' }
  end

  describe '.dev_group' do
    it 'raises an exception' do
      expect { described_class.dev_group }.to raise_error("Invalid remote: dev")
    end
  end
end
