# Monthly Release

GitLab releases a new minor version (`X.Y`) every month on the 22nd. The history
and reasoning behind this schedule can be found [on the blog].

The process begins seven **working days** before the 22nd. The [release manager]
should begin the monthly release process *no later than* the 9th.

The release manager should make sure there's a work in progress blog post
available for the next release the moment the previous release has been
published. This allows other developers to leave comments about the release,
instead of having to note them down elsewhere.

[on the blog]: https://about.gitlab.com/2015/12/07/why-we-shift-objectives-and-not-release-dates-at-gitlab/
[release manager]: release-manager.md

## Process

### 1. Create an issue to track the release

In order to keep track of the various tasks that need to happen each day leading
up to the final release, we create an issue on the [GitLab CE issue tracker] and
update it as we progress.

1. Create the issue using the
   [`monthly_issue`](rake-tasks.md#monthly_issueversion) Rake task:

    ```sh
    # NOTE: This command is an example! Update it to reflect new version numbers.
    bundle exec rake "monthly_issue[8.2.0]"
    ```

1. You may want to **bookmark** the issue until it's closed at the end of the
   release cycle.

[GitLab CE issue tracker]: https://gitlab.com/gitlab-org/gitlab-ce/issues

### 2. Complete the daily release tasks

Once the release schedule begins, each work day has something that needs to be
done. Perform the tasks and mark them as complete in the issue as you progress.

If you're not sure what to do for any task, [check the guides](../README.md#guides).

---

[Return to Guides](../README.md#guides)
