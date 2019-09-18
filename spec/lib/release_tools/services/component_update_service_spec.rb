# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Services::ComponentUpdateService do
  let(:internal_client) { double('ReleaseTools::GitlabClient') }
  let(:last_pages_commit) { 'abc123f' }
  let(:target_branch) { 'test-auto-deploy-001' }
  let(:component_versions) { { 'GITLAB_PAGES_VERSION' => 'v1' } }

  subject(:service) { described_class.new(target_branch) }

  before do
    allow(service).to receive(:gitlab_client).and_return(internal_client)
    allow(ReleaseTools::ComponentVersions).to receive(:get)
                                                .with(ReleaseTools::Project::GitlabEe, target_branch)
                                                .and_return(component_versions)
  end

  describe '#execute' do
    it 'updates component versions' do
      expect(service).to receive(:latest_successful_ref)
                           .with(ReleaseTools::Project::GitlabPages)
                           .and_return(last_pages_commit)
                           .once
      expect(internal_client).to receive(:project_path)
                                   .with(ReleaseTools::Project::GitlabEe)
                                   .and_return('a project path')
      expect(internal_client).to receive(:create_commit).with(
        'a project path',
        target_branch,
        'Update component versions',
        [
          { action: 'update', file_path: '/GITLAB_PAGES_VERSION', content: "#{last_pages_commit}\n" }
        ]
      )

      without_dry_run do
        service.execute
      end
    end

    context 'when no component changed' do
      it 'does not update component versions' do
        expect(service).to receive(:latest_successful_ref)
                             .with(ReleaseTools::Project::GitlabPages)
                             .and_return(component_versions['GITLAB_PAGES_VERSION'])
                             .once
        expect(internal_client).not_to receive(:create_commit)

        without_dry_run do
          service.execute
        end
      end
    end
  end
end
