# Release Manager

The release manager oversees the [monthly release] of GitLab as well as any
[patch releases] for that version.

## Onboarding
### Master checklist for onboarding of new release managers

The following checklist can be copied and pasted into a [new issue in the Organization project](https://gitlab.com/gitlab-com/organization/issues/new?issue[title]=Onboarding%20Release%20Manager%20[your%20name%20here]) 
to make sure the new release manager has the tools and some initial knowledge ready. 
The topics are ordered by priority and should be tackled by the new release manager
before starting the appointed release.

```
On-Boarding

- [ ] Make a note of your `dev` and `github` usernames and add them to this issue.
- [ ] Create a [new infra issue](https://gitlab.com/gitlab-com/infrastructure/issues/new?issue[title]=Chef%20access%20request), set it to confidential, and post your SSH username and public key there: [link to infrastructure issue]
- [ ] Make sure you have the [chef-repo](https://dev.gitlab.org/cookbooks/chef-repo) and [release-tools](https://gitlab.com/gitlab-org/release-tools) cloned locally, with all dependencies installed through [bundle](http://bundler.io/).
- [ ] Read through the [release guides](https://gitlab.com/gitlab-org/release-tools/blob/master/README.md#guides)
- [ ] Join #releases on Slack, and introduce yourself
- [ ] Master access on gitlab-ce  (dev and com)
- [ ] Master access on gitlab-ee (dev and com)
- [ ] Master access on gitlab-omnibus (dev) (already have on com)
- [ ] Developer access on chef-repo cookbook
- [ ] Get added to the [Release Managers team](https://github.com/orgs/gitlabhq/teams/release-managers) on GitHub.
- [ ] Make sure you have your [user added to Marvin](https://gitlab.com/gitlab-com/runbooks/blob/master/howto/manage-cog.md#add-a-user) on `#production` so you can tweet and broadcast messages

First Tasks

- [ ] Read the deploy docs: https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/staging.md and https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/deploying.md
- [ ] Be involved in the merge/pick to stable for at least one RC/Patch
- [ ] Perform the ce-to-ee merge at least once for a RC/Patch
- [ ] Tag the release for at least one RC/patch
- [ ] Join a staging deploy call
- [ ] Join a gitlab.com deploy call
- [ ] Deploy to staging at least once
- [ ] Deploy to gitlab.com at least once

  Last task (after the release)
  
- [ ] Ensure the next RM trainee has an onboarding issue like this one.

```

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

### Training

Release managers have the responsibility to deliver appropriate training to
the release manager trainees appointed to the same release.  

They'll need to make sure that trainees already have an [onboarding checklist](#master-checklist-for-onboarding-of-new-release-managers)
early on the release process, as well as giving them the opportunity to tackle
most of the release tasks during the release, at least once.

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
window, the release manager needs to pay particular attention to migrations that
may block the deploy. For example, migrations that take a long time (e.g.,
adding a column with a default value to the issues table) should be reviewed
carefully.

When the release packages are ready, the release manager should begin the
[deployment procedure].

## Further Reading

- ["Release Manager - The invisible hero"](https://about.gitlab.com/2015/06/25/release-manager-the-invisible-hero/) (2015-06-25)
- ["How we managed 49 monthly releases"](https://about.gitlab.com/2015/12/17/gitlab-release-process/) (2015-12-17)

[deployment procedure]: https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/deploying.md
[monthly release]: monthly.md
[patch releases]: patch.md
[security releases]: security.md

---

[Return to Guides](../README.md#guides)
