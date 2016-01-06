# Patch Releases

Patches are released on an as-needed basis in order to fix regressions in the
current [monthly release] which cannot or should not wait until the next month.

The changes included and the timing of the release is at the discretion of the
[release manager].

## Process

### 1. Create an issue to track the patch release

In order to keep track of the various tasks that need to happen before a patch
release is considered "complete", we create an issue on the [GitLab CE issue
tracker] and update it as we progress.

1. Create the issue using the [`patch_issue`](rake-tasks.md#patch_issueversion)
   Rake task:

    ```sh
    # NOTE: This command is an example! Update it to reflect new version numbers.
    bundle exec rake "patch_issue[version]"
    ```

1. You may want to **bookmark** the issue until it's closed at the end of the
   release cycle.

Generally, you should create a new patch issue immediately after the current
monthly release or previous patch release is completed.

### 2. Pick specific changes into the `stable` branches

A patch release is made up of one or more merge requests that have been merged
into the `master` branch of GitLab CE or EE, and which then need to be [cherry
picked] into the respective `stable` branches.

We cherry pick the single **merge commit** that results from accepting a merge
request and which may have been made up of more than one commit. This means we
only have to perform one pick per merge request and reduces the chances of
missing commits.

1. Make sure you have the latest changes to `master`:

    ```sh
    git checkout master
    git pull origin master
    ```

1. Check out the `stable` branch:

    ```sh
    # NOTE: This command is an example! Update it to reflect new version numbers.
    git checkout 8-3-stable
    ```

1. Cherry-pick the **merge commit** from `master`:

    ```sh
    # NOTE: This command is an example! Update it to reflect the actual SHA.
    git cherry-pick 450ea191 -m 1
    ```

1. If necessary, update `CHANGELOG` (or `CHANGELOG-EE`) and then amend the
   previous cherry pick commit:

    ```sh
    git add CHANGELOG
    git commit --amend --no-edit
    ```

1. Push the updated `stable` branch:

    ```sh
    # NOTE: This command is an example! Update it to reflect new version numbers.
    git push origin 8-3-stable
    ```

1. Switch back to the `master` branch and update `CHANGELOG` to include changes
   for the patch version. Commit and push.

1. As merges are picked and stable branches updated, it can be helpful to post
   a note in the merge request's discussion, both as a reminder to yourself of
   what's already been done and to update anyone else interested:

    ```
    Picked into `8-3-stable`
    ```

1. [Update any notes](release-manager.md#pre-release) from the regression issue
   to reflect their latest status.

### 3. Complete the patch release tasks

Use the patch issue created earlier to keep track of the process and mark off
tasks as you complete them.

[monthly release]: monthly.md
[release manager]: release-manager.md
[GitLab CE issue tracker]: https://gitlab.com/gitlab-org/gitlab-ce/issues
[cherry picked]: https://git-scm.com/docs/git-cherry-pick

---

[Return to Guides](../README.md#guides)
