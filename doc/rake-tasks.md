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

1. Edit `.env` to add the API endpoint (you probably want
   `https://gitlab.com/api/v4`) and your personal API access token (**Profile
   Settings** > **Account**).

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
| `TEST=true`     | Don't push anything to remotes                             |
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

---

[Return to Guides](../README.md#guides)
