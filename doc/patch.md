# Patch Releases

Patches are released on an as-needed basis in order to fix regressions in the
current or previous [monthly releases].

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

It's a good idea to create a new patch issue immediately after the current
monthly release or previous patch release is completed.

### 2. Pick specific changes into the `stable` branches

Follow the [Pick specific changes into the `stable` branches][pick-changes-into-stable]
guide.

### 3. Complete the patch release tasks

Use the patch issue created earlier to keep track of the process and mark off
tasks as you complete them.

[monthly releases]: monthly.md
[release manager]: release-manager.md
[GitLab CE issue tracker]: https://gitlab.com/gitlab-org/gitlab-ce/issues
[pick-changes-into-stable]: pick-changes-into-stable.md

---

[Return to Guides](../README.md#guides)
