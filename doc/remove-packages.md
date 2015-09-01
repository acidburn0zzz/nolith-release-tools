# Remove packages from [packages.gitlab.com](https://packages.gitlab.com/gitlab/)

In the event that something goes wrong with a release, you can remove packages
from [packages.gitlab.com] by following the [packagecloud documentation].

## Requirements

1. Install the `package_cloud` Ruby gem:

    ```sh
    sudo gem install package_cloud
    ```

1. Have an email and password for [packages.gitlab.com].

    ***TODO (rspeicher):*** Add details about how to find/create a login if you don't have one?

## Example

Be sure to provide the `--url` argument to override the default of
`packagecloud.io`:

```sh
package_cloud yank --url https://packages.gitlab.com gitlab/gitlab-ce/el/6 gitlab-ce-7.10.2~omnibus-1.x86_64.rpm
```

A first-time run of this command should look similar to this:

```sh
Looking for repository at gitlab/gitlab-ce... No config file exists at /Users/marin/.packagecloud. Login to create one.
Email:
marin@gitlab.com
Password:
<password entry>

Got your token. Writing a config file to /Users/marin/.packagecloud... success!
Attempting to yank package at gitlab/gitlab-ce/el/6/gitlab-ce-7.10.2~omnibus-1.x86_64.rpm...done!
```

[packages.gitlab.com]: https://packages.gitlab.com/
[packagecloud documentation]: https://packagecloud.io/docs#yank_pkg
