require 'spec_helper'
require 'project/helm_gitlab'

describe Project::HelmGitlab do

  describe '.path' do
    it { expect(described_class.path).to eq 'charts/gitlab' }
  end
end
