# Creating Release Candidates

Release Candidates (RCs) are pre-release versions of the next major version of
GitLab CE and EE. The first RC (RC1) is typically created six **working days**
before the official release and is used for [manual QA testing].

Every release must have at least one RC. It's not uncommon to have a second, and
sometimes even a third.

[manual QA testing]: qa-checklist.md

## Guides

### Creating RC1

***Note:*** *Before proceeding, ensure that CE's `master` branch is merged into
EE's. See the [Merge GitLab CE into EE](merge-ce-into-ee.md#merging-ce-master-into-ee-master)
guide.*

1. [Update the "Installation from Source" guide](#update-the-installation-from-source-guide)
1. [Create the Update guide](#create-the-update-guide)
1. [Tag the RC version](#tag-the-rc-version)

### Creating subsequent RCs

1. [Tag the RC version](#tag-the-rc-version)

## Tasks

### Update the "Installation from Source" guide

***Note:*** *This only needs to be done for the GitLab CE repository. Changes
will be merged into GitLab EE.*

1. Update the name of the `stable` branch in **Clone the Source**.
   There are two occurrences.
1. Ensure the `gitlab-workhorse` version in **Install gitlab-workhorse** matches
   the [required version][GITLAB_WORKHORSE_VERSION].
1. Depending on changes in the upcoming release, you may need to add or remove
   sections. For example, in GitLab 8.0 we had to add the section about
   installing `gitlab-workhorse` (called `gitlab-git-http-server` at the time).

### Create the Update guide

Each major release of GitLab needs a corresponding [update guide](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc/update)
with instructions on how to manually upgrade from the previous major release.

***Note:*** *GitLab CE and EE each have specific guides that need to be created.
Make sure to do both!*

***Note:*** *For the examples below, we're going to be using GitLab 8.2 as an
example of the upcoming release, and 8.1 as an example of the previous release.*

#### GitLab CE

***Note:*** *This only needs to be done for the GitLab CE repository. Changes
will be merged into GitLab EE.*

1. Copy the previous update guide to use as a template:

    ```sh
    # NOTE: This command is an example! Update it to reflect new version numbers.
    cp doc/update/8.0-to-8.1.md doc/update/8.1-to-8.2.md
    ```

1. Update the name of the `X-Y-stable[-ee]` branches in **Get latest code**.
   There are two occurrences.
1. Ensure the `gitlab-shell` version in **Update gitlab-shell** matches the
   [required version][GITLAB_SHELL_VERSION].
1. Ensure the `gitlab-workhorse` version in **Update gitlab-workhorse** matches
   the [required version][GITLAB_WORKHORSE_VERSION].
1. Update the names of the `X-Y-stable` branches in **Update configuration
   files**. There are six occurrences.
1. Update references to the "previous version" in **Things went south?** and the
   link to the previous guide.
1. Add any special instructions specific to this version. For example, maybe
   this version adds a new external dependency not in the previous version.
1. Read through the entire guide to make sure it makes sense. For example, maybe
   the previous version required special steps that no longer apply this
   version.

#### GitLab EE

GitLab EE releases include guides to migrate from the CE version of a major
release to the EE version of the same release.

1. Copy the previous update guide to use as a template:

    ```sh
    # NOTE: This command is an example! Update it to reflect new version numbers.
    cp doc/update/8.1-ce-to-ee.md doc/update/8.2-ce-to-ee.md
    ```

1. Update the version numbers in the top-level header and introduction. There
   are three occurrences.
1. Update the name of the `stable` branch in **Get the EE code**.
1. Update the names of the `X-Y-stable` branches in **Update config files**.
1. Update the version number in **Things went south?** and the name of the
   `stable` branch in **Revert the code to the previous version**.

### Tag the RC version

Use the [`release[version]`](rake-tasks.md#release-version) Rake task:

```sh
# NOTE: This command is an example! Update it to reflect new version numbers.
bundle exec rake "release[8.2.0.rc1]"
```

[GITLAB_SHELL_VERSION]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/GITLAB_SHELL_VERSION
[GITLAB_WORKHORSE_VERSION]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/GITLAB_WORKHORSE_VERSION

---

[Return to Guides](../README.md#guides)
