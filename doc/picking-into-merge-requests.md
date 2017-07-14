## Create EE preparing release MR

1. Create a new branch from the stable branch, ensuring it is up to date. Append `-patch-x` or `-preparing-RCx` depending on the patch release or RC being worked on.
```
git fetch origin 9-3-stable-ee
git checkout 9-3-stable-ee
git checkout -b 9-3-stable-ee-patch-5
```

1. Push the branch to GitLab.com
```
git push origin `git rev-parse --abbrev-ref HEAD`
```

1. Create MR with URL provided and closely follow steps below, e.g. https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/new?merge_request%5Bsource_branch%5D=9-3-stable-ee-patch-5
1.  Change target branch to the stable branch for that release
  - **NOTE:** Do this first as title/description will be lost
1. Set title to "WIP: Preparing 9.3.3-ee release"
1. Use new template for description
1. Assign to self
1. Add Release label
1. Set milestone to 9.3
1. `/cc` other release managers and trainees in a comment
1. Use template steps to begin picking MRs


## Merge CE stable changes to EE

git fetch origin 9-3-stable-ee
git checkout 9-3-stable-ee
git checkout -b 9-3-stable-ee-patch-5-ce-to-ee

# PS: Should repeat for stable as well in case things were directly merged
git fetch git@gitlab.com:gitlab-org/gitlab-ce.git 9-3-stable-patch-5

git branch 9-3-stable-patch-5-ce FETCH_HEAD
git merge 9-3-stable-patch-5-ce

# Fix conflicts

# If no complicated conflicts update 9-3-stable-ee
git push origin `git rev-parse --abbrev-ref HEAD`:9-3-stable-ee-patch-5

# Else create new MR
git push origin `git rev-parse --abbrev-ref HEAD`
