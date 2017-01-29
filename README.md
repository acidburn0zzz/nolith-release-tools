# GitLab Release Tools

This repository contains instructions and tools for releasing new versions of
GitLab Community Edition (CE) and Enterprise Edition (EE).

The goal is to provide clear instructions and procedures for our entire release
process, along with automated tools, to help anyone perform the role of [Release
Manager](doc/release-manager.md).

## Guides

- [What is a release manager?](doc/release-manager.md)
- [How to release new minor versions of GitLab each month](doc/monthly.md)
- [How to release patch versions of GitLab](doc/patch.md)
- [How to release security fixes for GitLab](doc/security.md)
- [How to pick specific changes into `stable` branches](doc/pick-changes-into-stable.md)
- [How to merge CE into EE](doc/merge-ce-into-ee.md)
- [How to create release candidates for new major versions of GitLab](doc/release-candidates.md)
- [How to perform manual QA testing](doc/qa-checklist.md)
- [How to push to multiple remotes at once](doc/push-to-multiple-remotes.md)
- [How to remove packages from packages.gitlab.com](doc/remove-packages.md)
- [How to push a new omnibus tag version](doc/omnibus-tag.md)
- [Required permissions to tag and deploy a release](doc/permissions.md)
- [Rake tasks](doc/rake-tasks.md)
- [Pro tips](doc/pro-tips.md)
- [Release template files](https://gitlab.com/gitlab-org/release-tools/tree/master/templates)

## Development

[![build status](https://gitlab.com/gitlab-org/release-tools/badges/master/build.svg)](https://gitlab.com/gitlab-org/release-tools/commits/master)
[![coverage report](https://gitlab.com/gitlab-org/release-tools/badges/master/coverage.svg)](http://gitlab-org.gitlab.io/release-tools/coverage/)
