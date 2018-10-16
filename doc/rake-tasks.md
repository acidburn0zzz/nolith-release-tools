# Rake Tasks

This project includes several Rake tasks to automate parts of the release
process.

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

## `cherry_pick[version]`

This task will cherry-pick merge requests into the [preparation
branches](#patch_merge_requestversion) for the specified version.

### Examples

```sh
# Cherry-pick merge requests in CE and EE labeled `Pick into 11.4` into the
# `11-4-stable[-ee]-prepare-rc6` branches.
bundle exec rake "cherry_pick[11.4.0-rc6]"

# Cherry-pick merge requests in CE and EE labeled `Pick into 11.3` into the
# `11-3-stable[-ee]-patch-6` branches.
bundle exec rake "cherry_pick[11.3.6]"
```

## `monthly_issue[version]`

This task will either return the URL of a monthly release issue if one already
exists for `version`, or it will create a new one and return the URL.

An issue created with this Rake task has the following properties:

- Its title is "Release X.Y" (e.g., "Release 8.3")
- Its description is the monthly release issue template
- It is assigned to the authenticated user
- It is assigned to the release's milestone
- It is labeled "Release"

### Examples

```sh
bundle exec rake "monthly_issue[8.3.0]"

--> Issue "Release 8.3" created.
    https://gitlab.com/gitlab-org/gitlab-ce/issues/3977
```

## `patch_issue[version]`

This task will either return the URL of a patch issue if one already exists for
`version`, or it will create a new one and return the URL.

An issue created with this Rake task has the following properties:

- Its title is "Release X.Y.Z" (e.g., "Release 10.6.4")
- Its description is the patch release issue template
- It is assigned to the authenticated user
- It is assigned to the release's milestone
- It is labeled "Release"

### Examples

```sh
bundle exec rake "patch_issue[10.6.4]"

--> Issue "Release 8.3.1" created.
    https://gitlab.com/gitlab-org/release/tasks/issues/153
```

## `patch_merge_request[version]`

This task will create preparation merge requests in CE and EE for the specified
patch version, and will return the URLs to both.

Merge requests created with this Rake task have the following properties:

- Its title is "WIP: Prepare X.Y.Z release" (e.g., "WIP: Prepare 8.3.1 release")
- Its description is the [patch merge request template]
- It is assigned to the authenticated user
- It is assigned to the release's milestone
- It is labeled "Release"

### Examples

```sh
bundle exec rake 'patch_merge_request[10.4.20]'

--> Merge Request "WIP: Prepare 10.4.20 release" created.
    https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/17156
--> Merge Request "WIP: Prepare 10.4.20-ee release" created.
    https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/4561
```

[patch merge request template]: ../../templates/preparation_merge_request.md.erb

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

--> 11.1.0+rc5.ee.0
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

--> 11.1.0+rc5.ce.0
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

## `qa_issue[from,to,version]`

This task will create an issue that lists the Merge Requests introduced between
two references and return the URL of the new issue.

An issue created with this Rake task has the following properties:

- Its title is "X.Y.Z-rcN QA Issue" (e.g., "v11.0.0-rc1 QA Issue")
- Its description is the QA issue template
- It is assigned to the authenticated user
- It is assigned to the release's milestone
- It is labeled "QA task"

### Arguments

| argument  | required | description                                      |
| ------    | -----    | -----------                                      |
| `from`    | yes      | SHA, branch, or tag                              |
| `to`      | yes      | SHA, branch, or tag                              |
| `version` | no       | Version used for the issue title and description |

If no `version` argument is provided, it will be inferred from the `to`
argument, for example `v11.1.0-rc5` will become `11.1.0-rc5`.

### Examples

```sh
bundle exec rake "qa_issue[10-8-stable,v11.0.0-rc1,v11.0.0-rc1]"

# Do not create the issue, but output the final description
TEST=true bundle exec rake "qa_issue[v11.0.0-rc12,v11.0.0-rc13,11.0.0-rc13]"
```

## `security_qa_issue[from,to,version]`

This task does the same as the [`qa_issue[from,to,version]`](#qa_issuefromtoversion)
task but forces the `SECURITY=true` flag.

### Examples

```sh
bundle exec rake "security_qa_issue[v11.1.1,v11.1.2,11.1.2]"

# Do not create the issue, but output the final description
TEST=true bundle exec rake "security_qa_issue[v11.1.1,v11.1.2,11.1.2]"
```

## `release_managers:auth[username]`

This task will check if the provided `gitlab.com` username is present in the
[`config/release_managers.yml`] definitions.

### Examples

```sh
$ bundle exec rake "release_managers:auth[valid-username]"

$ bundle exec rake "release_managers:auth[invalid-username]"
invalid-username is not an authorized release manager!
```

## `release_managers:sync`

This task will read configuration data from [`config/release_managers.yml`] and
sync the membership of the following groups:

- [gitlab-org/release/managers] on production
- [gitlab/release/managers] on dev

Users in the configuration file but not in the groups will be added; users in
the groups but not in the configuration file will be removed.

[gitlab-org/release/managers]: https://gitlab.com/gitlab-org/release/managers
[gitlab/release/managers]: https://dev.gitlab.org/groups/gitlab/release/managers

### Examples

```sh
bundle exec rake release_managers:sync

--> Syncing dev
    Adding jane-doe to gitlab/release/managers
    Removing john-smith from gitlab/release/managers
--> Syncing production
    Adding jane-doe to gitlab-org/release/managers
    Removing john-smith from gitlab-org/release/managers
```


## `security_patch_issue[version]`

This task will either return the URL of a patch issue if one already exists for
`version`, or it will create a new one and return the URL.

An issue created with this Rake task has the following properties:

- Its title is "Release X.Y.Z" (e.g., "Release 8.3.1")
- Its description is the security patch release issue template
- It is assigned to the authenticated user
- It is assigned to the release's milestone
- It is labeled "Release"
- It is confidential

### Examples

```sh
bundle exec rake "security_patch_issue[8.3.1]"

--> Issue "Release 8.3.1" created.
    https://gitlab.com/gitlab-org/gitlab-ce/issues/4245
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

## `tag[version]`

This task will:

1. Create the `X-Y-stable` and `X-Y-stable-ee` branches off the current
   `master`s for CE and EE, respectively, if they don't yet exist.
1. Update the `VERSION` file in both `stable` branches created above.
1. Update changelogs for CE and EE
1. Create the `v[version]` and `v[version]-ee` tags, pointing to the respective
   branches created above.
1. Push all newly-created branches and tags to all remotes.

This task **will NOT**:

1. Release the packages to the public, see [publishing-packages doc](doc/publishing-packages.md).
1. Perform a [deploy](doc/release-manager.md#deployment)

### Configuration

| Option          | Purpose                                                    |
| ------          | -------                                                    |
| `CE=false`      | Skip CE release                                            |
| `EE=false`      | Skip EE release                                            |
| `TEST=true`     | Don't push anything to remotes; don't create issues        |
| `SECURITY=true` | Treat this as a security release, using only `dev` remotes |

### Examples

```sh
# Tag 8.2 RC1:
bundle exec rake "tag[8.2.0-rc1]"

# Tag 8.2.3, but not for CE:
CE=false bundle exec rake "tag[8.2.3]"

# Tag 8.2.4, but not for EE:
EE=false bundle exec rake "tag[8.2.4]"

# Don't push branches or tags to remotes:
TEST=true bundle exec rake "tag[8.2.1]"

# Pull & push to `dev` only:
SECURITY=true bundle exec rake "tag[8.2.1]"
```

## `tag_security[version]`

This task does the same as the [`tag[version]`](#tagversion) task but forces the
`SECURITY=true` flag.

### Examples

```sh
# Tag 8.2 RC1:
bundle exec rake "tag_security[8.2.0-rc1]"

# Tag 8.2.3, but not for CE:
CE=false bundle exec rake "tag_security[8.2.3]"

# Tag 8.2.4, but not for EE:
EE=false bundle exec rake "tag_security[8.2.4]"

# Don't push branches or tags to remotes:
TEST=true bundle exec rake "tag_security[8.2.1]"
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
