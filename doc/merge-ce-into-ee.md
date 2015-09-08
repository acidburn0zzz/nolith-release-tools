# Merge GitLab CE into EE

This guide details the process for merging any GitLab CE branch (`master`, `8-0-stable`,
etc.) into the corresponding GitLab EE branch (`master`, `8-0-stable-ee`, etc.).

## Setup

1. We're going to pull CE into EE, so we first need a working copy of EE:

    ```sh
    git clone git@gitlab.com:gitlab-org/gitlab-ee.git

    cd gitlab-ee
    ```

1. Now add a remote inside the EE repository pointing to the CE repository:

    ```sh
    git remote add ce git@gitlab.com:gitlab-org/gitlab-ce.git
    ```

## Tasks

### Merging CE `master` into EE `master`

Before [releasing a new Release Candidate] of GitLab, we need to merge the
latest changes from CE into EE.

1. Make sure your EE repository has all the latest changes:

    ```sh
    git pull origin master
    ```

1. Then make sure your `ce` remote has the latest branch information:

    ```sh
    git fetch ce
    ```

1. Create a new branch off of `master` onto which we'll perform the merge:

    ```sh
    git checkout -b ce-to-ee
    ```

1. Now perform the merge:

    ```sh
    git merge --no-ff ce/master ce-to-ee
    ```

1. At this point it's not uncommon to encounter a merge conflict. Resolve it
   manually and commit the resolved merge, or if you're unable to resolve it,
   add the conflicted files as they are and request help in resolving it in the
   merge request we'll create in a later step.

1. Push the updated branch to `origin`:

    ```sh
    git push origin ce-to-ee
    ```

1. Submit a new [merge request in the GitLab EE project], selecting `ce-to-ee`
   as the **source** branch and `master` as the **target**.

[merge request in the GitLab EE project]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests

### Merging a CE stable branch into its EE counterpart

Before releasing a new stable version of GitLab, be it a major release or patch
release, we need to merge any changes from CE's stable branch for that version
into EE's.

In this example, we'll be releasing the first patch version of 7.14, 7.14.1.
Both CE and EE should already have branches called `7-14-stable` and
`7-14-stable-ee`, respectively, which were created during the Release Candidate
process.

1. Checkout a local branch, tracking the remote one:

    ```sh
    git checkout --track origin/7-14-stable-ee

    # The command above will fail if you've already checked out the stable
    # branch during a previous release. Switch to your local branch instead:
    git checkout 7-14-stable-ee
    ```

1. Make sure your local branch has all the latest changes:

    ```sh
    git pull origin 7-14-stable-ee
    ```

1. Then make sure your `ce` remote has the latest branch information:

    ```sh
    git fetch ce
    ```

1. Now perform the merge:

    ```sh
    git merge --no-ff ce/7-14-stable 7-14-stable-ee
    ```

1. At this point there will be a merge conflict, but likely only on the
   `VERSION` file. Resolve it and commit the merge.

1. Push the updated branch to `origin`:

    ```sh
    git push origin 7-14-stable-ee
    ```

---

[Return to Guides](../README.md#guides)
