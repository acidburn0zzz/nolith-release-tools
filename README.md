# Release tools

## !!! Before using this tool make sure you synced CE and EE


## Clone this repo

    git clone git@dev.gitlab.org:gitlab/release-tools.git
    cd release-tools

## Release candidate

    bundle exec rake release["7.5.0.rc1"]


What it does?

* checkout 7-5-stable (creates from master if not exists)
* change version to 7.5.0.rc1 and push all remotes
* create git tag v7.5.0.rc1 and push to all remotes
* checkout 7-5-stable-ee (creates from EE master if not exists)
* change version to 7.5.0.rc1-ee and push all remotes
* create git tag v7.5.0.rc1-ee and push to all remotes


## Release

    bundle exec rake release["7.5.0"]

What it does?

* checkout 7-5-stable (creates from master if not exists)
* change version to 7.5.0 and push all remotes
* create git tag v7.5.0 and push to all remotes
* checkout 7-5-stable-ee (creates from EE master if not exists)
* change version to 7.5.0-ee and push all remotes
* create git tag v7.5.0-ee and push to all remotes

## Patch release

    bundle exec rake release["7.5.1"]


What it does?

* checkout 7-5-stable (creates from master if not exists)
* change version to 7.5.1 and push all remotes
* create git tag v7.5.1 and push to all remotes
* checkout 7-5-stable-ee (creates from EE master if not exists)
* change version to 7.5.1-ee and push all remotes
* create git tag v7.5.1-ee and push to all remotes
