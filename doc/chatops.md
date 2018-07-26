# ChatOps

Several [Rake tasks](./rake-tasks.md) are available to be run via [GitLab
ChatOps][chatops].

Performing these tasks via ChatOps offers some important benefits:

- release-tools doesn't need to be configured with access tokens
- Task runs won't be interrupted by spotty internet connections or
  random computer reboots
- Anyone can follow the progress of a task by viewing its CI job
- The release manager doesn't need to switch away from Slack as frequently

[chatops]: https://gitlab.com/gitlab-com/chatops

## Preparation

Before you're able to run any ChatOps commands, your Slack account needs to be
authenticated to the ChatOps project. Run `/chatops` in Slack to introduce
yourself to the bot, who will help get you authenticated.

Once authenticated, you can run `/chatops help` to see a list of available
commands. Commands implemented for release tools are all performed via `/chatops
run [command]`, and are outlined below.

All `run` commands take a `--help` flag that details their available options.

## Commands

### `publish`

Publishes packages for the specified version.

> NOTE: If for some reason the ChatOps command isn't working as expected, you
> can run the equivalent [`rake publish`](./rake-tasks.md#publishversion)
> command locally.

#### Examples

```
/chatops run publish 11.1.0-rc1

/chatops run publish 11.1.0

/chatops run publish 11.0.7
```

### `qa_issue`

Create a QA issue with differences between two specified tags.

> NOTE: If for some reason the ChatOps command isn't working as expected, you
> can run the equivalent [`rake qa_issue`](./rake-tasks.md#qa_issuefromtoversion)
> command locally.

#### Examples

```
/chatops run qa_issue v11.1.0-rc1..v11.1.0-rc2
```

### Release Issues

Create a task issue for either a monthly, patch, or security release.

ChatOps will run the [`monthly_issue`], [`patch_issue`], or
[`security_patch_issue`] task depending on where the command was run, and what
version was specified.

> NOTE: If for some reason the ChatOps command isn't working as expected, you
> can run the equivalent [`rake`](./rake-tasks.md) task command locally.

[`monthly_issue`]: ./rake-tasks.md#monthly_issueversion
[`patch_issue`]: ./rake-tasks.md#patch_issueversion
[`security_patch_issue`]: ./rake-tasks.md#security_patch_issueversion

#### Examples

```
# Create a security release task issue from the #security channel
/chatops run release_issue 11.1.2
```

```
# Create a monthly release task issue from anywhere else
/chatops run release_issue 11.1.0
```

```
# Create a patch or RC task issue from anywhere else
/chatops run release_issue 11.1.1

/chatops run release_issue 11.1.0-rc5
```

### `tag`

Tags the specified version.

> NOTE: If for some reason the ChatOps command isn't working as expected, you
> can run the equivalent [`rake tag`](./rake-tasks.md#tagversion)
> command locally.

#### Options

| flag         | description                                                       |
| ----         | -----------                                                       |
| `--security` | Perform a [security tagging](./rake-tasks.md#tag_securityversion) |

#### Examples

```
/chatops run tag 11.0.0-rc10

/chatops run tag 11.0.1

/chatops run tag --security 11.0.2
```

## Technical details

ChatOps commands are implemented in the [ChatOps project][chatops-commands].
Those commands use [triggers](https://docs.gitlab.com/ee/ci/triggers/) to
trigger the `chatops` job in this project, which runs
[`bin/chatops`](../bin/chatops), which triggers the appropriate [Rake
task](./rake-tasks.md).

[chatops-commands]: https://gitlab.com/gitlab-com/chatops/tree/master/lib/chatops/commands

---

[Return to Documentation](../README.md#documentation)
