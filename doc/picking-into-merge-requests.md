## Create EE preparing release MR

git fetch origin 9-3-stable-ee
git checkout 9-3-stable-ee
git checkout -b 9-3-stable-ee-patch-5
git push origin `git rev-parse --abbrev-ref HEAD`
#git push origin 9-3-stable-ee-patch-5

Create MR with URL provided
https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/new?merge_request%5Bsource_branch%5D=9-3-stable-ee-patch-5

Change target branch to the stable branch for that release
 -> Do this first as title/description will be lost

Set title to "WIP: Preparing 9.3.3-ee release"
Use new template for description
Assign to self
Add Release label
Set milestone to 9.3
/cc other release managers and trainees in a comment

Use template steps to begin picking MRs


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
