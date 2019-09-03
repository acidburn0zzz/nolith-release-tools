# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Project::HelmGitlab do
  it_behaves_like 'project #remotes'
  it_behaves_like 'project #to_s'

  describe '.path' do
    it { expect(described_class.path).to eq 'gitlab-org/charts/gitlab' }
  end
end
