# Rake Tasks

This project includes several Rake tasks to automate parts of the release
process.

Generally these tasks are executed via [ChatOps](./chatops.md) and should not
need to be run directly.

## Setup

1. Install the required dependencies with Bundler:

    ```sh
    bundle install
    ```

1. Several of the tasks require API access to a GitLab instance. We store the
   endpoint and private token data in the `.env` file which is not added to
   source control. Copy the `.env.example` file:

    ```sh
    cp .env.example .env
    ```

1. Edit `.env` to add your personal API access token [(**Profile
   Settings** > **Access Tokens**)](https://gitlab.com/profile/personal_access_tokens).

   1. We recommend you to create a new access token for the Release Manager process, in gitlab.com:
        ```
        Name: Release Manager Token
        Expires at: one month after the release on which you are RM
        Scopes: [x] api
        ```

   1. Add the access token to `.env`:
       ```
        GITLAB_API_PRIVATE_TOKEN=YOUR_TOKEN
       ```

1. Edit `.env` to add the Slack URL. The value should be in the Team vault in 'release-tools'
    ```
    # - Search 'release-tools' in the Team vault and copy the value
    # - Update SLACK_TAG_URL with the value:
    SLACK_TAG_URL="https://hooks.slack.com/services/foo/bar/baz"
    ```

## `release` tasks

Tasks in this namespace automate release-related activities such as tagging and
publishing packages.

### `release:issue[version]`

Create a task issue for the specified version.

### `release:merge[version]`

Cherry-pick merge requests into the preparation branches for the specified
version.

### `release:prepare[version]`

Prepare for a release of the specified version.

For monthly versions (`X.Y.0`), it will:

1. Create the `Pick into X.Y` group label
1. Create the `X-Y-stable[-ee]` branches
1. Create the monthly release task issue
1. Create the RC1 task issue
1. Create the RC1 preparation MRs

For patch versions (`X.Y.Z` or `X.Y.0-rcX`), it will:

1. Create the task issue
1. Create the preparation MRs

### `release:qa[from,to]`

Create an issue that lists changes introduced between `from` and `to` and return
the URL of the new issue.

### `release:tag[version]`

Tag the specified version.

## `security` tasks

Tasks in this namespace largely mirror their [`release`
counterparts](#release-tasks), but with additional safeguards in place for
performing a security release of GitLab.

### `security:issue[version]`

Create a confidential task issue for the specified version.

### `security:merge[merge_master]`

Merge validated merge requests in the security repositories for GitLab projects.

If `merge_master` is truthy, it will also merge security MRs targeting `master`
(default: `false`).

### `security:prepare[version]`

Create security issues for an upcoming security release. One issue is created
for each of the backported releases.

For example, if the current patch versions of the last three minor releases are
`11.9.1`, `11.8.3`, and `11.7.6`, it will create confidential task issues for
`11.9.2`, `11.8.4`, and `11.7.7`.

### `security:qa[from,to]`

Create a confidential QA issue, listing changes between `from` and `to` in order
to verify changes in a release.

### `security:tag[version]`

Tag the specified version as a security release.

## `green_master:<ee|ce|all>[trigger_build]`

This task will show us the selected `sha` associated with the latest `master`
branch that had a successful pipeline run.  When `trigger_build` is `true`, it
will send the signal to `omnibus-gitlab` to start that build.

When running `green_master:all`, it will run both the CE and EE builds
synchronously.  Keep this in mind if on a time constraint.

### Examples

```sh
# Informational gathering only
% bundle exec rake green_master:ee
Found EE Green Master at 50b5b74315b8e8c440305d48cc8d26c3ef843bf4

% bundle exec rake green_master:ce
Found CE Green Master at 5ff775fdef99eeec1f25bea7baf5480fa402f714

% bundle exec rake green_master:all[true]
Found EE Green Master at 50b5b74315b8e8c440305d48cc8d26c3ef843bf4
Found CE Green Master at 5ff775fdef99eeec1f25bea7baf5480fa402f714

# Actually triggers a build (Example output)
% bundle exec rake green_master:ee[true]
Found EE Green Master at 50b5b74315b8e8c440305d48cc8d26c3ef843bf4
trigger build: 50b5b74315b8e8c440305d48cc8d26c3ef843bf4 for Project::GitlabCe
Pipeline triggered: https://dev.gitlab.org/gitlab/omnibus-gitlab/pipelines/205527
...........................................
Pipeline succeeded in 43 minutes.

% bundle exec rake green_master:ce[true]
Found CE Green Master at 5ff775fdef99eeec1f25bea7baf5480fa402f714
trigger build: 5ff775fdef99eeec1f25bea7baf5480fa402f714 for Project::GitlabCe
Pipeline triggered: https://dev.gitlab.org/gitlab/omnibus-gitlab/pipelines/205528
...........................................
Pipeline succeeded in 43 minutes.

% bundle exec rake green_master:all[true]
Found EE Green Master at 50b5b74315b8e8c440305d48cc8d26c3ef843bf4
trigger build: 50b5b74315b8e8c440305d48cc8d26c3ef843bf4 for Project::GitlabCe
Pipeline triggered: https://dev.gitlab.org/gitlab/omnibus-gitlab/pipelines/205527
...........................................
Pipeline succeeded in 43 minutes.
Found CE Green Master at 5ff775fdef99eeec1f25bea7baf5480fa402f714
trigger build: 5ff775fdef99eeec1f25bea7baf5480fa402f714 for Project::GitlabCe
Pipeline triggered: https://dev.gitlab.org/gitlab/omnibus-gitlab/pipelines/205528
...........................................
Pipeline succeeded in 43 minutes.
```

## `publish[version]`

This task will publish all available CE and EE packages for a specified version.

### Configuration

| Option      | Purpose                                |
| ------      | -------                                |
| `TEST=true` | Don't actually play the manual actions |

### Examples

``` sh
$ bundle exec rake 'publish[11.1.0-rc4]'

Nothing to be done for 11.1.0+rc4.ee.0: https://dev.gitlab.org/gitlab/omnibus-gitlab/pipelines/86189
Nothing to be done for 11.1.0+rc4.ce.0: https://dev.gitlab.org/gitlab/omnibus-gitlab/pipelines/86193
```

```sh
$ bundle exec rake "publish[11.1.0-rc5]"

--> 11.1.0+rc5.ee.0: https://dev.gitlab.org/gitlab/omnibus-gitlab/pipelines/86357
    Ubuntu-14.04-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2599976
    Ubuntu-16.04-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2599977
    Ubuntu-18.04-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2599978
    Debian-7-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2599979
    Debian-8-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2599980
    Debian-9.1-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2599981
    CentOS-6-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2599982
    CentOS-7-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2599983
    OpenSUSE-42.3-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2599984
    SLES-12-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2599985
    Docker-Release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2599987
    AWS: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2599988
    QA-Tag: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2599989
    Raspberry-Pi-2-Jessie-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2599993

--> 11.1.0+rc5.ce.0: https://dev.gitlab.org/gitlab/omnibus-gitlab/pipelines/86362
    Ubuntu-14.04-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2600293
    Ubuntu-16.04-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2600294
    Ubuntu-18.04-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2600295
    Debian-7-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2600296
    Debian-8-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2600297
    Debian-9.1-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2600298
    CentOS-6-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2600299
    CentOS-7-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2600300
    OpenSUSE-42.3-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2600301
    SLES-12-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2600302
    Docker-Release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2600304
    AWS: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2600305
    QA-Tag: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2600306
    Raspberry-Pi-2-Jessie-release: https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/2600310
```

## `sync`

This task ensures that the `master` branches for both CE and EE are in sync
between all the remotes.

If you manually [push to multiple remotes](push-to-multiple-remotes.md) during
the release process, you can safely skip this task.

### Configuration

| Option      | Purpose                        |
| ------      | -------                        |
| `CE=false`  | Skip CE repository             |
| `EE=false`  | Skip EE repository             |
| `OG=false`  | Skip omnibus-gitlab repository |
| `TEST=true` | Don't push anything to remotes |

### Examples

```bash
bundle exec rake sync
```

## `helm:tag_chart[version,gitlab_version]`

This task will:

1. Create the `X-Y-stable` branch off the current `master` using the
   `version` argument, if the branch doesn't yet exist.
1. Runs the `bump_version` script in the `charts/gitlab` repo; passing the
   `version`, and `gitlab_version` (if provided) for the branches above.
1. Create the `v[version]` tag, pointing to the respective branch created above.
   But only if the `gitlab_version` is not an RC. (we currently don't tag RC charts)  
1. Push all newly-created branches and tags to all remotes.
1. Runs the `bump_version` script in the master branch, only passing the
   `version`. And only running if `version` is
   newer than what is already in master.
1. Pushes the master branch to all remotes.

Details on the chart version scheme can be found
in the `charts/gitlab` repo's [release documentation](https://gitlab.com/charts/gitlab/blob/master/doc/development/release.md)

### Arguments

| argument         | required | description                                      |
| ------           | -----    | -----------                                      |
| `version`        | yes      | Chart version to tag                             |
| `gitlab_version` | no       | GitLab image version to use in the branch        |

If `gitlab_version` is provided, the version of GitLab used in the chart will be
updated before tagging.

If `version` is empty, but a valid `gitlab_version` has been provided, then the
script will tag using an increment of the previous tagged release. This scenario
is only intended to be used by CI release automation, where it is being run in a
project that is only aware of the desired GitLab Version.

### Configuration

| Option          | Purpose                                |
| ------          | -------                                |
| `TEST=true`     | Don't push anything to remotes         |

### Examples

```sh
# Create 0-3-stable branch, but don't tag, for testing using 11.1 RC1:
bundle exec rake "helm:tag_chart[0.3.0,11.1.0-rc1]"

# Tag 0.3.1, and include GitLab Version 11.1.1
bundle exec rake "helm:tag_chart[0.3.1,11.1.1]"

# Tag 0.3.2, but don't change the GitLab version:
bundle exec rake "helm:tag_chart[0.3.2]"

# Don't push branches or tags to remotes:
TEST=true bundle exec rake "helm:tag_chart[0.3.3]"

# Tag using an increment of the last tag, and update the GitLab version
bundle exec rake "helm:tag_chart[,11.1.2]"
```

## `upstream_merge`

This task will:

1. Merge the latest CE `master` into the latest EE `master`
1. Push the merge to a new (unique per day) branch
1. Create a Merge Request that will include:
  1. A list the files for which conflicts need to be resolved
  1. Mentions of the last ones who updated the conflicting files

### Configuration

| Option          | Purpose |
| ------          | ------- |
| `NO_MENTION=true` | Don't mention people in the MR description (wrap their usernames in backticks) |
| `TEST=true`     | Don't push the new branch, nor create a MR for it |
| `FORCE=true`    | Create a branch and MR even if another upstream merge is already in progress |

### Examples

```sh
# Merge latest CE `master` into latest EE `master` and create a MR:
bundle exec rake upstream_merge

# Don't push the new branch nor create a MR for it:
TEST=true bundle exec rake upstream_merge

# Create a branch and MR even if one is already in progress:
FORCE=true bundle exec rake upstream_merge
```

---

[Return to Documentation](../README.md#documentation)

[`config/release_managers.yml`]: ../config/release_managers.yml
