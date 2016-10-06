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

## Overall process

Follow the standard [patch release process](patch.md#process), with some
additional considerations:

1. Mark any applicable previous releases as vulnerable on [version.gitlab.com].
1. Ensure the blog post discloses as much information about the vulnerability as
   is responsibly possible. We aim for clarity and transparency, and try to
   avoid secrecy and ambiguity.
1. Coordinate with the Marketing team to send out a security newsletter.
1. If the vulnerability was responsibly disclosed to us by a security
   researcher, ensure they're [publicly acknowledged] and thank them again
   privately as well.

[version.gitlab.com]: https://version.gitlab.com/
[publicly acknowledged]: https://about.gitlab.com/vulnerability-acknowledgements/

## Technical process

### Before the release

When preparing a security release, the most important thing is to **always work
with the `dev` remote**:

- Merge requests that fix CE security issues should be submitted on
  https://dev.gitlab.org/gitlab/gitlabhq against the
  [`security` branch](https://dev.gitlab.org/gitlab/gitlabhq/tree/security)

- Merge requests that fix EE security issues should be submitted on
  https://dev.gitlab.org/gitlab/gitlab-ee against the
  [`security` branch](https://dev.gitlab.org/gitlab/gitlab-ee/tree/security)

### About the security branch

The `security` branch is "parallel" to `master` and ensure no one inadvertedly
exposes security fixes on GitLab.com, since the `security` -> `master` merge is
a manual and conscious operation.

`master` can and should be merged frequently to `security`, but `security` can
only be merged once all the security fixes it contains are released as part of
official releases (and possibly backports).

### Cherry-picking

As usual cherry-pick the merge request commits you need, but this time **push to
`dev` only**:

```shell
$ git push dev X-Y-stable
```

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
