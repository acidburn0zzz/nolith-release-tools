# Release Manager

The release manager oversees the [monthly release] of GitLab as well as any
[patch releases] for that version.

## Responsibilities

### Pre-release

The release manager's job begins with creating and tracking the [release
issue](monthly.md#1-create-an-issue-to-track-the-release).

Any task can be delegated to any member of the team who can perform it. When
delegating a task, be sure to mention a person directly rather than asking
something indirect like "Can someone help me do QA?". If someone is unavailable
to perform a task, ask someone else, or ask Job or a previous release manager to
find someone. The monthly releases are a company-wide effort, and should not
fall entirely on the release manager's shoulders.

Once the [regressions issue is created](rake-tasks.md#regression_issueversion),
the release manager is responsible for tracking and managing it. This usually
involves checking the reported issues and any available fixes for those issues,
and ensuring they are included either in the next release candidate or the final
release.

### Release

After performing all of his or her pre-release tasks, and releasing the final
version of the monthly release, the release manager gets to relax, sometimes for
as long as **six hours**!

But no release is ever perfect, and the bug reports will start to come in as
users update to the latest version. That's where patch releases come in.

### Post-release

The amount and scheduling of [patch releases] is entirely at the discretion of
the release manager (with the exception of [security releases], which should be
addressed immediately).

If a bug affects a large number of users and/or a critical piece of
functionality, it's fine to release a patch with only one fix. Sometimes a patch
will include five or more minor fixes. The release manager should use his or her
best judgement to determine when a patch release is warranted. We strive to
continue releasing patches until all known regressions for that release are
addressed.

### Deployment

With the help of the infrastructure team, the release manager is also
responsible for deploying the latest version to GitLab.com. During the merge
window, the release manager needs to pay particular attention to migrations
that may block the deploy. For example, migrations take a long time (e.g. add
a column with a default value to the issues table) should be reviewed
carefully.

When the release packages are ready, the release manager should
begin the [deployment procedure].

## Further Reading

- ["Release Manager - The invisible hero"](https://about.gitlab.com/2015/06/25/release-manager-the-invisible-hero/) (2015-06-25)
- ["How we managed 49 monthly releases"](https://about.gitlab.com/2015/12/17/gitlab-release-process/) (2015-12-17)

[deployment procedure]: https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/deploying.md
[monthly release]: monthly.md
[patch releases]: patch.md
[security releases]: security.md

---

[Return to Guides](../README.md#guides)
