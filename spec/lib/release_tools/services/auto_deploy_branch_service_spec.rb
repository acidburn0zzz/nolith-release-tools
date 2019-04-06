# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Services::AutoDeployBranchService do
  let(:internal_client) { double('ReleaseTools::GitlabClient', current_milestone: double(title: '11.10'), update_variable: double) }
  let(:internal_client_ops) { spy('ReleaseTools::GitlabOpsClient') }
  let(:branch_commit) { double(latest_successful: double(id: '1234')) }

  subject(:service) { described_class.new('branch-name') }

  before do
    allow(service).to receive(:gitlab_client).and_return(internal_client)
    allow(service).to receive(:gitlab_ops_client).and_return(internal_client_ops)
  end

  describe '#create_branches!', :silence_stdout do
    it 'creates auto-deploy branches for gitlab-ee and gitlab-ce' do
      branch_name = 'branch-name'

      expect(ReleaseTools::Commits).to receive(:new).and_return(branch_commit).exactly(4).times
      expect(internal_client_ops).to receive(:create_branch).with(
        branch_name,
        '1234',
        ReleaseTools::Project::Deployer
      )
      expect(internal_client).to receive(:create_branch).with(
        branch_name,
        '1234',
        ReleaseTools::Project::GitlabCe
      )
      expect(internal_client).to receive(:create_branch).with(
        branch_name,
        '1234',
        ReleaseTools::Project::GitlabEe
      )
      expect(internal_client).to receive(:create_branch).with(
        branch_name,
        '1234',
        ReleaseTools::Project::OmnibusGitlab
      )
      expect(internal_client).to receive(:update_variable).with(
        'gitlab-org/release-tools',
        'AUTO_DEPLOY_BRANCH',
        branch_name
      )

      without_dry_run do
        service.create_branches!
      end
    end
  end
end

describe ReleaseTools::Services::AutoDeployBranchService do
  describe '#filter_branches' do
    subject(:service) do
      VCR.use_cassette('branches/list') do
        wut = described_class.new(1)
        wut.filter_branches
      end
    end

    it 'finds all auto-deploy branches' do
      expect(subject).to eq(version: "11.11", branch: "11-11-auto-deploy-0900001-ee")
    end
  end
end
