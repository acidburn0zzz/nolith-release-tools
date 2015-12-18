# Release Manager

The release manager oversees the [monthly release] of GitLab as well as any
[patch releases] for that version.

## Responsibilities

### Pre-release

The release manager's job begins with creating and tracking the [release
issue](monthly.md#create-an-issue-to-track-the-release).

Any task can be delegated to any member of the team who can perform it. When
delegating a task, be sure to mention a person directly rather than asking
something indirect like "Can someone help me do QA?". If someone is unavailable
to perform a task, ask someone else, or ask Job or a previous release manager to
find someone. The monthly releases are a company-wide effort, and should not
fall entirely on the release manager's shoulders.

Once the **regressions issue** is created four working days before the release,
the release manager is responsible for tracking and managing it. This usually
involves checking the reported issues and any available fixes for those issues,
and ensuring they are included either in the next release candidate or the final
release.

A "best practice" we've developed is editing the notes to reflect their status
as they are addressed. For example, a regression note might look like this after
being reported:

```text
#3531 - User profile pages are timing out - Fix in !1234
```

After being addressed, the release manager might edit it to look like this:

```text
~~#3531 - User profile pages are timing out - Fix in !1234~~

**rspeicher:** Merged, to be included in RC2.
```

The strikethrough formatting makes it easier to scan through the list to find
issues that still need to be addressed, and the added note from the release
manager (**rspeicher**, in this case) gives anyone following the issue a clear
indication of when the fix will be released.

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

## Further Reading

- ["Release Manager - The invisible hero"](https://about.gitlab.com/2015/06/25/release-manager-the-invisible-hero/) (2015-06-25)
- ["How we managed 49 monthly releases"](https://about.gitlab.com/2015/12/17/gitlab-release-process/) (2015-12-17)

[monthly release]: monthly.md
[patch releases]: patch.md
[security releases]: security.md

---

[Return to Guides](../README.md#guides)
