# frozen_string_literal: true

module ReleaseTools
  module Qa
    class IssuePresenter
      attr_reader :merge_requests, :issue, :version

      def initialize(merge_requests, issue, version)
        @merge_requests = merge_requests
        @issue = issue
        @version = version
      end

      def present
        (+"").tap do |text|
          if issue.exists?
            text << issue.remote_issuable.description
          else
            text << header_text
          end
          text << formatter.lines.join("\n")
          text << automated_qa_text
        end
      end

      private

      def header_text
        <<~HEREDOC
          ## Process

          Each engineer validates and checks off each of their assigned QA task(s).
          1. Check off each Merge Request changes that you've tested successfully and note any issues you've created and check them off as they are resolved.
          1. If a problem is found:
              * Create an issue for it and add a sub bullet item under the corresponding validation checklist task. Link the issue there.
              * Add the severity label
              * Raise the problem in the discussion and tag relevant Engineering and Product managers.
          1. If a regression is found:
              * Create an issue for it
              * Add the severity label and the regression label
              * Raise the regression in the discussion and tag relevant Engineering and Product managers.

          General Quality info can be found in the [Quality Handbook](https://about.gitlab.com/handbook/engineering/quality/).

          Note: If you are assigned tasks outside your normal work hours, you're not expected to work overtime. Please complete the tasks as soon
          as possible during your normal work hours.

          ## Deadline

          QA testing on [staging.gitlab.com](https://staging.gitlab.com/users/sign_in) for this issue should be completed by **#{due_date.strftime('%Y-%m-%d %H:%M')} UTC**.
          After this deadline has passed, the issue will be closed automatically.

          If the deadline has passed, please perform your task as soon as possible anyway (during your normal work hours). It's important that the testing is
          performed, even if deployment has proceeded to a later stage.

          ## Testing changes requiring admin or console access

          If testing changes requires admin or console access which you might be lacking on [staging.gitlab.com](https://staging.gitlab.com),
          create a virtual machine locally or using one of the cloud service providers, and install the latest nightly
          package from [packages.gitlab.com/gitlab/nightly-builds](https://packages.gitlab.com/gitlab/nightly-builds).

          ## Testing CE only changes

          When testing changes in CE specifically, use [dev.gitlab.org](https://dev.gitlab.org) as it is running a nightly version of GitLab CE.  If it is determined
          that the dev instance does not suffice, create a virtual machine to install the CE package and complete an install to perform the necessary testing.
          Currently we do not build CE packages to match that of the version in this QA issue.
          The best course of action would be to find the closest CE package from our nightly repository. [packages.gitlab.com/gitlab/nightly-builds](https://packages.gitlab.com/gitlab/nightly-builds)

          ## Merge Requests tested in #{version}

        HEREDOC
      end

      def automated_qa_text
        "## Automated QA for #{version}\n\n#{issue.qa_job ? qa_job_found_text : qa_job_not_found_text}"
      end

      def qa_job_found_text
        <<~HEREDOC
          A QA job was automatically started: <#{issue.qa_job&.web_url}>

          Also, if the #{version} security package has been deployed to staging,
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
        HEREDOC
      end

      def qa_job_not_found_text
        <<~HEREDOC
          No QA job could be found for this release!

          You will need to set up a dedicated environment for #{version}
          by following the following steps:

          ### Prepare the environments for testing the security fixes

          <details>
            <summary>Instructions to prepare environment</summary>

          1. In [Google Cloud Console](https://console.cloud.google.com/) (access to this
            should have been granted during on-boarding), create a new VM instance (in the
            `gitlab-internal` project) from the `qa-security-1cpu-3-75gb-ram-ubuntu-16-04-lts`
            instance template for each version of GitLab.
          1. Find the `.deb` package to install:
              1. First find the pipeline for the `#{version.to_omnibus(ee: true)}`
                tag in the [pipelines page].
              1. Then on the pipeline page, click the `Ubuntu-16.04-staging` job
                in the `Upload:gitlab_com` stage (or the `Staging_upload` stage
                for versions prior to 11.5), you will need the job ID later.
          1. Install the `.deb` package from the job artifact:
              1. SSH into the VM via the GCP console.
              1. Create a `install-gitlab.sh` script in your home folder:
                  ```bash
                  TEMP_DEB="$(mktemp)"
                  GITLAB_PACKAGE="https://dev.gitlab.org/api/v4/projects/gitlab%2Fomnibus-gitlab/jobs/${JOB_ID}/artifacts/pkg/ubuntu-xenial/gitlab-ee_${GITLAB_VERSION}-ee.0_amd64.deb"
                  curl -H "PRIVATE-TOKEN: $DEV_TOKEN" "$GITLAB_PACKAGE" -o "$TEMP_DEB" &&
                  sudo dpkg -i "$TEMP_DEB"
                  rm -f "$TEMP_DEB"
                  ```
                  * `$DEV_TOKEN` needs to be set with a `dev.gitlab.org` personal access token
                  so that the script can download the package
                  * `$JOB_ID` needs to be set with the `Ubuntu-16.04-staging` job ID
                  * `$GITLAB_VERSION` needs to be set with the version (without the `-ee` prefix, e.g. `11.4.10`).
              1. Change the script's permission with `chmod +x install-gitlab.sh`.
              1. Run the script with `./install-gitlab.sh`.
              1. Once GitLab installed, set the `external_url` in `/etc/gitlab/gitlab.rb`
                with `sudo vim /etc/gitlab/gitlab.rb`. You can find the VM's IP in the GCP console.
              1. Reconfigure and restart GitLab with `sudo gitlab-ctl reconfigure && sudo gitlab-ctl restart`.
              1. You may need to wait a few minutes after the above command finishes
                before the instance is actually accessible.
          1. Set the `root`'s user password:
              1. Visit http://IP_OF_THE_GCP_VM and change `root`'s password.
              1. Once the environments are ready, capture the information to add to the QA issue.

          </details>

          ### Automated QA

          <details>
            <summary>Instructions to perform automated QA</summary>

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
              token under the `GitLab QA - Access tokens` 1Password items)
              * `$QA_IMAGE` the URL of the QA image
              * `$QA_ENV_URL` with the URL of the environment where the package has been
                deployed (usually https://staging.gitlab.com for the current version, and
                `http://IP_OF_THE_GCP_VM` for back-ported versions).
              * `$GITLAB_USERNAME` with `root`.
              * `$GITLAB_ADMIN_USERNAME` with `$GITLAB_USERNAME`.
              * `$GITLAB_PASSWORD` with the password you've set for the `root` user.
              * `$GITLAB_ADMIN_PASSWORD` with `$GITLAB_PASSWORD`.
              * `$GITHUB_ACCESS_TOKEN` with a valid GitHub API token that can access the https://github.com/gitlab-qa/test-project project
              * `$DEV_USERNAME` with your `dev` username
              * `$DEV_TOKEN` with a valid `dev` personal access token that has
                the `read_registry` scope
              ```
              › export QA_IMAGE="dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ee-qa:#{version.to_ee}"
              › export QA_ENV_URL="<QA_ENV_URL>"
              › export GITLAB_USERNAME="root"
              › export GITLAB_ADMIN_USERNAME="$GITLAB_USERNAME"
              › export GITLAB_PASSWORD="<GITLAB_PASSWORD>"
              › export GITLAB_ADMIN_PASSWORD="$GITLAB_PASSWORD"
              › export GITHUB_ACCESS_TOKEN="<GITHUB_ACCESS_TOKEN>"
              › export DEV_USERNAME="<DEV_USERNAME>"
              › export DEV_TOKEN="<DEV_TOKEN>"
              ```

          - [ ] Update `gitlab-qa` if needed

            ```
            › gem install gitlab-qa
            ```

          - [ ] Log into the `dev` container registry

            ```
            › docker login --username "$DEV_USERNAME" --password "$DEV_TOKEN" dev.gitlab.org:5005
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

          </details>

          ### Coordinate the Manual QA validation of the release

          <details>
          <summary>Click for details</summary>

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

            </details>

        HEREDOC
      end

      def sort_merge_requests
        ReleaseTools::Qa::IssuableSortByLabels.new(merge_requests).sort_by_labels(*labels)
      end

      def formatter
        ReleaseTools::Qa::Formatters::MergeRequestsFormatter.new(
          merge_requests: sort_merge_requests,
          project_path: issue.project.path
        )
      end

      def labels
        [ReleaseTools::Qa::TEAM_LABELS]
      end

      def due_date
        utc_date = DateTime.now.new_offset(0)

        if utc_date.friday? || utc_date.saturday?
          utc_date + 48.hours
        else
          utc_date + 24.hours
        end
      end
    end
  end
end
