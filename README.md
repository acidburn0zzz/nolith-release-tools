# Release tools

## Clone this repo

    git clone git@dev.gitlab.org:gitlab/release-tools.git
    cd release-tools

## Requirements

* EE master has latest changes from CE master
* If x-x-stable branch exists make sure EE x-x-stable-ee has latest changes from CE x-x-stable 

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


## CE or EE only

You can skip release for Community Edition or Enterprise Edition. 
Just set ENV variable with software you want to skip. For example command 
below will create patch release for EE only.

    CE=false be rake release['7.2.4']


## Developemnt & Test

If you need to test tool before use with push to official remotes - set TEST env. 
In this case everything will be executed as usual except git push command will be ignored. 


    TEST=true be rake release['7.2.4']

## Sync CE master between different remotes and sync EE master between EE remotes

 
    be rake sync
