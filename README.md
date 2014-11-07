# Release tools


## RC1

How to use:

    bundle exec rake release:rc1["7.5.0"]

What it does?

* change version to 7.5.0.rc1 and push all remotes
* create git tag v7.5.0.rc1 and push to all remotes
* create stable branch 7-5-stable from master
* push stable branch to all remotes
