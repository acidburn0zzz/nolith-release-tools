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

- Its title is "Release X.Y.Z" (e.g., "Release 8.3.1")
- Its description is the patch release issue template
- It is assigned to the authenticated user
- It is assigned to the release's milestone
- It is labeled "Release"

### Examples

```sh
bundle exec rake "patch_issue[8.3.1]"

--> Issue "Release 8.3.1" created.
    https://gitlab.com/gitlab-org/gitlab-ce/issues/4245
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

## `release[version]`

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
# Release 8.2 RC1:
bundle exec rake "release[8.2.0-rc1]"

# Release 8.2.3, but not for CE:
CE=false bundle exec rake "release[8.2.3]"

# Release 8.2.4, but not for EE:
EE=false bundle exec rake "release[8.2.4]"

# Don't push branches or tags to remotes:
TEST=true bundle exec rake "release[8.2.1]"

# Pull & push to `dev` only:
SECURITY=true bundle exec rake "release[8.2.1]"

# Output an issue body rather than creating one:
TEST=true bundle exec rake "patch_issue[8.2.1]"
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

## `release_managers:sync`

This task will read configuration data from [`config/release_managers.yml`] and
sync the membership of the following groups:

- [gitlab-org/release/managers] on production
- [gitlab/release/managers] on dev

Users in the configuration file but not in the groups will be added; users in
the groups but not in the configuration file will be removed.

[`config/release_managers.yml`]: ../config/release_managers.yml
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

## `security_release[version]`

This task does the same as the `release[version]` task but force the
`SECURITY=true` flag.

### Examples

```sh
# Release 8.2 RC1:
bundle exec rake "security_release[8.2.0-rc1]"

# Release 8.2.3, but not for CE:
CE=false bundle exec rake "security_release[8.2.3]"

# Release 8.2.4, but not for EE:
EE=false bundle exec rake "security_release[8.2.4]"

# Don't push branches or tags to remotes:
TEST=true bundle exec rake "security_release[8.2.1]"
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

[Return to Guides](../README.md#guides)
