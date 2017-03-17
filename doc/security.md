# Security Releases

Security vulnerabilities in GitLab and its dependencies are to be addressed with
the highest priority.

Security releases are naturally very similar to [patch releases](patch.md), but
on a much shorter timeline. The goal is to make a security release available as
soon as possible, while ensuring that the security issue is properly addressed
and that the fix does not introduce regressions.

Depending on the severity and the attack surface of the vulnerability, an
immediate patch release consisting of just the security fix may be warranted.
For less severe issues, it may be acceptable to include the fix in a future
patch. This is one case where the release manager _does not_ have final say
concerning a release, and he or she should consult with the GitLab development
team as well as any applicable security experts, such as the person disclosing
the issue.

## Backporting

For medium-level security issues, we may consider backporting to the previous
two monthly releases (e.g. 8.8 and 8.9 if 8.10 is released), but this will
be decided on a case-by-case basis in consultation with the rest of the GitLab
development team.

For very serious security issues, there is
[precedent](https://about.gitlab.com/2016/05/02/cve-2016-4340-patches/)
to backport security fixes to even more monthly releases of GitLab. This again
will be decided on a case-by-case basis.

If a security fix warrants backporting to previous releases, doing a single blog
post that mentions all of the patches at once is acceptable.

## What to include

A security release, even one for the latest monthly release, should _only_
include the changes necessary to resolve the security vulnerabilities. Including
fixes for regressions in a security patch increases the chances of breaking
something, both for users and for our packaging and release process.

The only exception to this policy is [release
candidates](release-candidates.md). If the monthly release process is in
progress as we're preparing for a security release, it's acceptable for a new RC
to include both security fixes and regression fixes. Care should be taken to
coordinate the publishing of an RC package with the other security patches so as
to not disclose the security vulnerabilities publicly before we're ready to
disclose them.

## Process

### Before the release

When preparing a security release, the most important thing is to **always work
with the `dev` remote**:

- Merge requests that fix CE security issues should be submitted on
  https://dev.gitlab.org/gitlab/gitlabhq against the
  [`security` branch](https://dev.gitlab.org/gitlab/gitlabhq/tree/security)

- Merge requests that fix EE security issues should be submitted on
  https://dev.gitlab.org/gitlab/gitlab-ee against the
  [`security` branch](https://dev.gitlab.org/gitlab/gitlab-ee/tree/security)

### 1. Create an issue to track the security patch release

In order to keep track of the various tasks that need to happen before a security
patch release is considered "complete", we create an issue on the [GitLab CE issue
tracker] and update it as we progress.

1. Create the issue using the [`security_patch_issue`](rake-tasks.md#security_patch_issueversion)
   Rake task:

    ```sh
    # NOTE: This command is an example! Update it to reflect new version numbers.
    bundle exec rake "security_patch_issue[version]"
    ```

### 2. Complete the security patch release tasks

Use the security patch issue created above to keep track of the process and
mark off tasks as you complete them.

### About the security branch

The `security` branch is "parallel" to `master` and ensure no one inadvertedly
exposes security fixes on GitLab.com, since the `security` -> `master` merge is
a manual and conscious operation.

`master` can and should be merged frequently to `security`, but `security` can
only be merged once all the security fixes it contains are released as part of
official releases (and possibly backports).

### Merging CE stable into EE stable

To merge CE into EE stable, you can either add
https://dev.gitlab.org/gitlab/gitlabhq.git as a new remote or fetch the remote
and reference it in the merge with `FETCH_HEAD`, and remember to **push to `dev`
only**:

```shell
$ git fetch git@dev.gitlab.org:gitlab/gitlabhq.git X-Y-stable
$ git merge --no-ff FETCH_HEAD X-Y-stable-ee
$ git push dev X-Y-stable-ee
```

**Note:** Please change `FETCH_HEAD` to `dev/X-Y-stable` in the commit message so it's
obvious what was the merge remotes & branches when viewing the history.

### About the blog post

Create the blog post merge request **only once all the EE and CE packages are built and
available on https://packages.gitlab.com/gitlab.

Before that, you can share the draft either in a private snippet, a confidential
issue or by any other secure and private means.

### After the release

After the packages are built and announced on our blog, you **should not** merge
the `security` branches to their `master` counterparts but only cherry-pick the
security merge commits that are already part of a tagged (and announced) release
to `master` and sync `master` to all the remotes.

This is because new security fixes can be merged to `security` between the time
you prepare a security release and the time you're done with it.

---

[Return to Guides](../README.md#guides)
