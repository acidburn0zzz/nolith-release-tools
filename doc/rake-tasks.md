# Rake Tasks

This project includes several Rake tasks to automate parts of the release
process.

## Setup

Install the required dependencies with Bundler:

```sh
bundle install
```

## `monthly_post[version]`

This task will generate the description body to be used for the [monthly
release](monthly.md#create-an-issue-to-track-the-release) issue.

### Examples

```sh
bundle exec rake "monthly_post[8.3.0]"
```

## `release[version]`

This task will:

1. Create the `X-Y-stable` and `X-Y-stable-ee` branches off the current
   `master`s for CE and EE, respectively, if they don't yet exist.
1. Update the `VERSION` file in both `stable` branches created above.
1. Create the `v[version]` and `v[version]-ee` tags, pointing to the respective
   branches created above.
1. Pushes all newly-created branches and tags to all remotes.

### Configuration

| Option      | Purpose                        |
| ------      | -------                        |
| `CE=false`  | Skip CE repository             |
| `EE=false`  | Skip EE repository             |
| `TEST=true` | Don't push anything to remotes |

### Examples

```sh
# Release 8.2 RC1:
bundle exec rake "release[8.2.0.rc1]"

# Release 8.2.3, but not for CE:
CE=false bundle exec rake "release[8.2.3]"

# Release 8.2.4, but not for EE:
EE=false bundle exec rake "release[8.2.4]"

# Don't push branches or tags to remotes:
TEST=true bundle exec rake "release[8.2.1]"
```

## `sync`

This task ensures that the `master` branches for both CE and EE are in sync
between all the remotes.

If you manually [push to multiple remotes](push-to-multiple-remotes.md) during
the release process, you can safely skip this task.

### Examples

```bash
bundle exec rake sync
```

---

[Return to Guides](../README.md#guides)
