# frozen_string_literal: true

module ReleaseTools
  module Deployments
    # Notifying of deployed merge requests that they will be included in the
    # next release.
    module ReleasedMergeRequestNotifier
      TEMPLATE = <<~COMMENT
        This merge request has been deployed to the pre.gitlab.com environment,
        and will be included in the upcoming [self-managed GitLab][self-managed]
        %<version>s release.

        <hr/>

        :robot: This comment is generated automatically using the
        [Release Tools][release-tools] project.

        /label ~published

        [self-managed]: https://about.gitlab.com/handbook/engineering/releases/#self-managed-releases-1
        [release-tools]: https://gitlab.com/gitlab-org/release-tools/
      COMMENT

      # The environment packages ready for release are deployed to.
      RELEASE_ENVIRONMENT = 'pre'

      # environment - The name of the environment that was deployed to.
      # deployments - An Array of `DeploymentTrackes::Deployment` instances,
      #               containing data about a deployment.
      # version - a String containing the version that was deployed.
      def self.notify(environment, deployments, version)
        return unless environment == RELEASE_ENVIRONMENT

        parsed_version = Version.new(version)

        # If the version format is something we don't recognise (e.g. we deploy
        # an auto deploy package to pre for some reason), we don't want to
        # notify merge requests about the deployment.
        return unless parsed_version.valid?

        # RC releases are deployed to pre at least once per release, and
        # possibly more times. If we were to create a comment for every RC
        # release this would lead to a lot of noise. It could also confuse
        # developers, as changes in an RC are not guaranteed to also go in the
        # final release.
        return if parsed_version.rc?

        comment = format(TEMPLATE, version: parsed_version.to_patch)

        MergeRequestUpdater
          .for_successful_deployments(deployments)
          .add_comment(comment)
      end
    end
  end
end
