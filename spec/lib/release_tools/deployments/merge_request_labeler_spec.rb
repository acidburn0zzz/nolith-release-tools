# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Deployments::MergeRequestLabeler do
  let(:labeler) { described_class.new }

  describe '#label_merge_requests' do
    context 'when deploying to an environment without a workflow label' do
      it 'does not update any merge requests' do
        deploy = ReleaseTools::Deployments::DeploymentTracker::Deployment
          .new(ReleaseTools::Project::GitlabEe, 1, 'success')

        expect(labeler).not_to receive(:update_merge_requests)

        labeler.label_merge_requests('kittens', [deploy])
      end
    end

    context 'when deploying to an environment with a workflow label' do
      it 'adds the workflow label to all merge requests' do
        deploy = ReleaseTools::Deployments::DeploymentTracker::Deployment
          .new(ReleaseTools::Project::GitlabEe, 1, 'success')

        merge_request =
          double(:merge_request, project_id: 2, iid: 3, labels: %w[foo])

        page = Gitlab::PaginatedResponse.new([merge_request])

        allow(ReleaseTools::GitlabClient)
          .to receive(:deployed_merge_requests)
          .with(ReleaseTools::Project::GitlabEe, 1)
          .and_return(page)

        expect(ReleaseTools::GitlabClient)
          .to receive(:create_merge_request_comment)
          .with(2, 3, '/label ~"workflow::staging"')

        labeler.label_merge_requests('gstg', [deploy])
      end

      it 'retries retrieving of merge requests when this fails' do
        stub_const(
          'ReleaseTools::Deployments::MergeRequestLabeler::RETRY_INTERVAL',
          0
        )

        deploy = ReleaseTools::Deployments::DeploymentTracker::Deployment
          .new(ReleaseTools::Project::GitlabEe, 1, 'success')

        page1_raised = false
        page2_raised = false

        mr1 = double(:merge_request, project_id: 2, iid: 3, labels: %w[foo])
        mr2 = double(:merge_request, project_id: 2, iid: 4, labels: %w[bar])

        page1 = Gitlab::PaginatedResponse.new([mr1])
        page2 = Gitlab::PaginatedResponse.new([mr2])

        allow(ReleaseTools::GitlabClient).to receive(:deployed_merge_requests) do
          if page1_raised
            page1
          else
            page1_raised = true
            raise gitlab_error(:InternalServerError)
          end
        end

        allow(page1).to receive(:has_next_page?).and_return(true)

        allow(page1).to receive(:next_page) do
          if page2_raised
            page2
          else
            page2_raised = true
            raise gitlab_error(:InternalServerError)
          end
        end

        expect(ReleaseTools::GitlabClient)
          .to receive(:create_merge_request_comment)
          .with(2, 3, '/label ~"workflow::staging"')

        expect(ReleaseTools::GitlabClient)
          .to receive(:create_merge_request_comment)
          .with(2, 4, '/label ~"workflow::staging"')

        labeler.label_merge_requests('gstg', [deploy])
      end

      it 'skips deployments that did not succeed' do
        deploy = ReleaseTools::Deployments::DeploymentTracker::Deployment
          .new(ReleaseTools::Project::GitlabEe, 1, 'failed')

        expect(labeler).not_to receive(:update_merge_requests)

        labeler.label_merge_requests('gstg', [deploy])
      end
    end
  end
end
