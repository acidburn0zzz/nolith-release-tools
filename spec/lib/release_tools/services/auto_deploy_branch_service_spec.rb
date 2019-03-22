# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Services::AutoDeployBranchService do
  # Unset the `TEST` environment variable that gets set by default
  def without_dry_run(&block)
    ClimateControl.modify(TEST: nil) do
      yield
    end
  end

  let(:internal_client) { spy('ReleaseTools::GitlabClient') }
  let(:branch_commit) { double(latest_successful: double(id: '1234')) }

  subject(:service) do
    VCR.use_cassette('milestones/active') do
      described_class.new('9000')
    end
  end

  before do
    allow(service).to receive(:client).and_return(internal_client)
  end

  describe '#create_auto_deploy_branches!' do
    it 'creates auto-deploy branches for gitlab-ee and gitlab-ce' do
      expect(ReleaseTools::Commits).to receive(:new).and_return(branch_commit).twice
      expect(internal_client).to receive(:create_branch).with(
        '11-10-auto-deploy-0009000-ee',
        '1234',
        ReleaseTools::Project::OmnibusGitlab
      )
      expect(internal_client).to receive(:create_branch).with(
        '11-10-auto-deploy-0009000-ee',
        '1234',
        ReleaseTools::Project::GitlabEe
      )
      without_dry_run do
        service.create_auto_deploy_branches!
      end
    end
  end
end
