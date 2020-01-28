# frozen_string_literal: true

module ReleaseTools
  module Deployments
    # Adding of workflow environment labels to deployed merge requests.
    class MergeRequestLabeler
      include ::SemanticLogger::Loggable

      # The base interval for retrying operations that failed, in seconds.
      RETRY_INTERVAL = 5

      # The workflow labels to apply to a merge request when it is deployed.
      #
      # The keys are the environments deployed to, the values the workflow label
      # to apply.
      DEPLOYMENT_LABELS = {
        'gstg' => 'workflow::staging',
        'gprd-cny' => 'workflow::canary',
        'gprd' => 'workflow::production'
      }.freeze

      # environment - The name of the environment that was deployed to.
      # deployments - An Array of `DeploymentTrackes::Deployment` instances,
      #               containing data about a deployment.
      def label_merge_requests(environment, deployments)
        workflow_label = DEPLOYMENT_LABELS[environment]

        unless workflow_label
          logger.warn(
            'Not updating merge requests as there is no workflow label for this environment',
            environment: environment
          )

          return
        end

        deployments.each do |deployment|
          next unless deployment.success?

          logger.info(
            'Adding workflow label to deployed merge requests',
            environment: environment,
            label: workflow_label,
            project: deployment.project
          )

          update_merge_requests(deployment, workflow_label)
        end
      end

      private

      def update_merge_requests(deployment, workflow_label)
        deployment_merge_requests(deployment) do |merge_requests|
          Parallel.each(merge_requests, in_threads: Etc.nprocessors) do |mr|
            retry_block do
              GitlabClient.create_merge_request_comment(
                mr.project_id,
                mr.iid,
                "/label ~#{workflow_label.inspect}"
              )
            end
          end
        end
      end

      def deployment_merge_requests(deploy)
        page = retry_block do
          GitlabClient.deployed_merge_requests(deploy.project, deploy.id)
        end

        while page
          yield page.each.to_a

          retry_block do
            page = page.next_page
          end
        end
      end

      def retry_block(&block)
        Retriable.retriable(base_interval: RETRY_INTERVAL, &block)
      end
    end
  end
end
