require_relative 'issue_presenter'

module Qa
  module Presenters
    class SecurityIssuePresenter < Qa::Presenters::IssuePresenter
      private

      def automated_qa_text
        <<~HEREDOC
          ## Automated QA for #{version}

          If the #{version} security package has been deployed to staging,
          you can just start a new [`Daily staging QA` pipeline] by clicking the
          "Play" button and wait for the pipeline to finish.

          ```sh
          Post the result of the test run here.
          ```

          If there are errors, create a new issue for each failing job (you can
          use the "New issue" button from the job page itself), in the
          https://gitlab.com/gitlab-org/quality/staging project and mention
          the `@gl-quality` group.

          [`Daily staging QA` pipeline]: https://gitlab.com/gitlab-org/quality/staging/pipeline_schedules

          Otherwise, you'll need to set up a dedicated environment for #{version}
          by following the following steps:

          ### Prepare the environments for testing the security fixes

          1. In [Google Cloud Console](https://console.cloud.google.com/) (access to this
            should have been granted during on-boarding), create a new VM instance (in the
            `gitlab-internal` project) from the `qa-security-1cpu-3-75gb-ram-ubuntu-16-04-lts`
            instance template for each version of GitLab.
          1. Find the `.deb` package to install:
            1. First find the pipeline for the `#{version.to_omnibus(ee: true)}`
              tag in the [pipelines page].
            1. Then on the pipeline page, click the `Ubuntu-16.04-staging` job
              in the `Staging_upload` stage.
            1. Browse the job's artifacts, and find the `.deb` package under
              `pkg/ubuntu-xenial/`.
            1. Copy the `Download` link location.
          1. Install the `.deb` package from the job artifact:
            1. SSH into the VM via the GCP console.
            1. Create a `install-gitlab.sh` script in your home folder:

              ```bash
              TEMP_DEB="$(mktemp)" &&
              curl -H "PRIVATE-TOKEN: $DEV_TOKEN" "$GITLAB_PACKAGE" -o "$TEMP_DEB" &&
              sudo dpkg -i "$TEMP_DEB"
              rm -f "$TEMP_DEB"
              ```
              `$DEV_TOKEN` needs to be set with a `dev.gitlab.org` personal access token
              so that the script can download the package, `$GITLAB_PACKAGE` needs to be
              set to the link location from the job's artifacts.
            1. Change the script's permission with `chmod +x install-gitlab.sh`.
            1. Run the script with `./install-gitlab.sh`.
            1. Once GitLab installed, set the `external_url` in `/etc/gitlab/gitlab.rb`
              with `sudo vim /etc/gitlab/gitlab.rb`. You can find the VM's IP in the GCP console.
            1. Reconfigure and restart GitLab with `sudo gitlab-ctl reconfigure && sudo gitlab-ctl restart`.
          1. Set the `root`'s user password:
            1. Visit http://IP_OF_THE_GCP_VM and change `root`'s password.
            1. Once the environments are ready, capture the information to add to the QA issue.

          ### Automated QA

          - (Optional) If the QA Docker image doesn't exist, you will need to build it
          manually on your machine, e.g.

            ```shell
            # In gitlab-ee
            › git fetch dev
            › git checkout #{version.tag(ee: true)}
            › cd qa
            › docker build -t dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ee-qa:#{version.to_ee} .
            ```
          - [ ] Make sure to export the following environment variables (you can find the
            password and tokens under the `GitLab QA` and `GitLab QA - Access tokens` 1Password items)
            * `<QA_ENV_URL>` with the URL of the environment where the package has been
              deployed (usually https://staging.gitlab.com for the current version, and
              `http://IP_OF_THE_GCP_VM` for back-ported versions).
            * `<ROOT_PASSWORD>` with the password you've set for the `root` user.
            * `<GITHUB_ACCESS_TOKEN>` with a valid GitHub API token that can access the
              `gitlab-qa/test-project` project.
            ```
            › export QA_IMAGE="dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ee-qa:#{version.to_ee}"
            › export QA_ENV_URL="<QA_ENV_URL>"
            › export GITLAB_USERNAME=root
            › export GITLAB_PASSWORD="<ROOT_PASSWORD>"
            › export GITHUB_ACCESS_TOKEN="<GITHUB_ACCESS_TOKEN>"
            ```

          - [ ] Update `gitlab-qa` if needed

            ```
            › gem install gitlab-qa
            ```
          - [ ] Automated QA completed. QA can be parallelized manually (for now):

            ```
            # Tab 1: This should take approximately 4.5 minutes

            › gitlab-qa Test::Instance::Any $QA_IMAGE $QA_ENV_URL -- qa/specs/features/api/ qa/specs/features/login/ qa/specs/features/merge_request/
            ```

            ```
            # Tab 2: This should take approximately 6 minutes

            › gitlab-qa Test::Instance::Any $QA_IMAGE $QA_ENV_URL -- qa/specs/features/project/
            ```

            ```
            # Tab 3: This should take approximately 5 minutes

            › gitlab-qa Test::Instance::Any $QA_IMAGE $QA_ENV_URL -- qa/specs/features/repository/
            ```
          - [ ] Post results as comments of this issue
          - [ ] Create `Automation Triage RELEASE_MAJOR_VERSION RC#` issues for all the
              automated QA failures (with failures logs + screenshots) and link it to this issue

          ### Coordinate the Manual QA validation of the release

          1. Notify the Security Engineer to verify the security fixes for the release.
            * The manner in which the security fixes are verified can be done in two ways.
                1. By the Quality Engineer executing the validation with close collaboration and guidance from the Security Engineer.
                1. By the Security Engineer executing the validation with the Quality Engineer monitoring the steps.
            * *Note*: When encountered with deadline and resource constraints, the work should be assigned for efficiency.
              Security Engineer should own verifying complex security validations while Quality Engineer is encouraged to help out with simpler validations.
              However it is important that the Security team signs off on the result of the validation.
          1. Ensure that all the items for validation are validated and checked off before moving forward.
          1. Hand off the release assignment.
            1. Once all the validation is completed, Quality Engineer un-assigns themselves
              from the release issue leaving only the Security Engineer and the Release Manager.

          [pipelines page]: https://dev.gitlab.org/gitlab/omnibus-gitlab/pipelines
        HEREDOC
      end
    end
  end
end
