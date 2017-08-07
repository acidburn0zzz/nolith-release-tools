## Create MR to prepare release

1. Create `X-Y-stable-patch-Z` and `X-Y-stable-ee-patch-Z` branches from their respective stable branches. Ensure the stable branch is up to date and append `-patch-x` or `-preparing-RCx` depending on the patch release or RC being worked on.
```
git fetch origin X-Y-stable-ee
git checkout -b X-Y-stable-ee-patch-Z origin/X-Y-stable-ee
```

1. Push the branch to GitLab.com
```
git push origin X-Y-stable-ee-patch-Z
```

1. Create an MR with the URL provided (e.g., https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/new?merge_request%5Bsource_branch%5D=9-3-stable-ee-patch-5) and closely follow the steps below:
  1. Change target branch to the stable branch for that release  
     **NOTE:** Do this first as title/description will be lost
  1. Set title to "WIP: Preparing 9.3.3-ee release"
  1. Generate template descriptions using the [preparation merge request template](../templates/preparation_merge_request.md.erb)
  1. Assign to self
  1. Add `Release` label
  1. Set milestone to `X.Y`
  1. `/cc` other release managers and trainees in a comment
  1. Use template steps to begin picking MRs

## Merge CE stable changes to EE

There are a few approaches to doing the CE->EE merge: CE `X-Y-stable-patch-Z` can be merged into the existing EE preparation MR, can be merged into a new MR to fix conflicts, or could even be merged into stable.

Keeping the stable branches clean can help if you unexpectedly need to do a security release on those branches. Beyond that the trade-offs are complexity, checking pipelines are green on the branch vs MR, and creating a workflow which allows you to do things quickly and in parallel.

### To merge CE into the EE MR

1. Check out an up to date  `X-Y-stable-ee-patch-Z` branch in your local EE repo, or pull changes.
```
git fetch origin
git checkout -b X-Y-stable-ee-patch-Z origin/X-Y-stable-ee-patch-Z
```

1. Fetch `X-Y-stable-patch-Z` branch from CE ready for merging
```
git fetch git@gitlab.com:gitlab-org/gitlab-ce.git X-Y-stable-patch-Z
```

1. Merge that branch into the current EE preparation branch
```
git merge FETCH_HEAD
```

1. Optional: repeat previous two steps with `X-Y-stable` to double check that no new changes have been introduced outside of the CE preparation MR.

1. Optional: Create a new branch if you'd like to fix conflicts in a separate MR

1. Fix simple conflicts and push
```
git push origin X-Y-stable-ee-patch-Z
```

1. Optional: Ask others to help fix conflicts in the MR.

## Merging preparation MRs into stable

1. Check that no commits have been added to stable
1. Consider doing a fast-forward merge manually from the shell. The main benefit is that the HEAD commit from the MR will be the same for `X-Y-stable`, allowing you save time waiting for pipelines to turn green.
1. When pipelines are green for `X-Y-stable` and `X-Y-stable-ee`, move on to tagging the release.
