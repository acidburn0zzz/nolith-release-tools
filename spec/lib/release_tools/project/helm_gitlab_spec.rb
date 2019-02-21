require 'spec_helper'

describe ReleaseTools::Project::HelmGitlab do
  describe '.path' do
    it { expect(described_class.path).to eq 'charts/gitlab' }
  end
end
