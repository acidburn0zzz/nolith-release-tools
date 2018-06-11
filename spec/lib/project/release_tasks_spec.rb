require 'spec_helper'
require 'project/release_tasks'

describe Project::ReleaseTasks do
  describe '.path' do
    it { expect(described_class.path).to eq 'gitlab-org/release/tasks' }
  end
end
