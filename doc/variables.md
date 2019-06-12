# release-tools CI variables

This project makes heavy use of environment variables for configuration. This
document aims to provide a reference for the most important ones, but is not
necessarily comprehensive.

## Instance tokens

- `DEV_API_PRIVATE_TOKEN` -- API access token for a user on `dev.gitlab.org`.
- `GITLAB_API_PRIVATE_TOKEN` -- API access token for a user on `gitlab.com`.
- `GITLAB_API_APPROVAL_TOKEN` -- API access token for a user on `gitlab.com`.
  Used for approving merge requests created by the user owning the
  `GITLAB_API_PRIVATE_TOKEN` token.
- `OPS_API_PRIVATE_TOKEN` -- API access token for a user on `ops.gitlab.net`.
- `RELEASE_BOT_DEV_TOKEN` -- API access token for
  [@gitlab-release-tools-bot][bot-dev] user on `dev.gitlab.org`.
- `RELEASE_BOT_OPS_TOKEN` -- API access token for
  [@gitlab-release-tools-bot][bot-ops] on `ops.gitlab.net`.
- `RELEASE_BOT_PRODUCTION_TOKEN` -- API access token for
  [@gitlab-release-tools-bot][bot-com] on `gitlab.com`
- `VERSION_API_PRIVATE_TOKEN` -- API access token for
  [@gitlab-release-tools-bot][bot-dev] on `version.gitlab.com`.

## SSH private keys

Private keys are used to push to repositories via SSH, rather than
authenticating over HTTPS with an access token.

- `RELEASE_BOT_PRIVATE_KEY` -- Private key for
  [@gitlab-release-tools-bot][bot-com].

## Auto-deploy

- `AUTO_DEPLOY_BRANCH` -- The current auto-deploy branch. Gets updated via API
  by auto-deploy jobs and **should not be changed manually.**
- `MERGE_TRAIN_TRIGGER_TOKEN` -- Used to trigger the merge train job after
  cherry-picking.
- `OMNIBUS_BUILD_TRIGGER_TOKEN` -- Used to trigger an Omnibus build.

## Miscellany

- `SENTRY_DSN` -- DSN for the `release-tools` project on
  [Sentry](https://sentry.gitlab.net/gitlab/release-tools/).
- `SLACK_CHATOPS_URL` -- Full Slack webhook URL for ChatOps responses.
- `SLACK_TAG_URL` -- Full Slack webhook URL for tagging notifications.
  notifications.

[bot-com]: https://gitlab.com/gitlab-release-tools-bot
[bot-dev]: https://dev.gitlab.org/gitlab-release-tools-bot
[bot-ops]: https://ops.gitlab.net/gitlab-release-tools-bot

---

[Return to Documentation](../README.md#documentation)
