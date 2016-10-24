# Permissions required

In order to be able to tag and deploy a release you need to ask for the
following permissions:

### Repositories

You should request **Master** access and the ability to push to protected
branches for the following repositories:

* [gitlab/gitlabhq](https://dev.gitlab.org/gitlab/gitlabhq)
* [gitlab/gitlab-ee](https://dev.gitlab.org/gitlab/gitlab-ee)
* [gitlab/omnibus-gitlab](https://dev.gitlab.org/gitlab/omnibus-gitlab)
* [gitlab-org/gitlab-ce](https://gitlab.com/gitlab-org/gitlab-ce)
* [gitlab-org/gitlab-ee](https://gitlab.com/gitlab-org/gitlab-ee)
* [gitlab-org/omnibus-gitlab]([https://gitlab.com/gitlab-org/omnibus-gitlab)

**Developer** access is required to:

* [cookbooks/chef-repo](https://dev.gitlab.org/cookbooks/chef-repo)

On GitHub you will need **Push** access to:

* [gitlabhq/gitlabhq](https://github.com/gitlabhq/gitlabhq)

### Chef Server

First make sure you have a copy of the [chef-repo project](https://dev.gitlab.org/cookbooks/chef-repo).

Now you need to request for an account on the Chef server, please [open a new issue](https://gitlab.com/gitlab-com/infrastructure/issues/new)
and an operations engineer will provide you with a private key that you can store in /path/to/chef-repo/.chef/your_username.pem in order
to have the `knife` tool configured. If all went well you can check if you
have access to the Chef server by running `knife status` from the
chef-repo directory.

Your `/path/to/chef-repo/.chef/knife.rb` file should looks similar to:

```ruby
# This file goes in chef-repo/.chef/knife.rb
#
# - Replace 'janedoe' with your username
# - Put your private key for chef.gitlab.com/gitlab in .chef/
#
# See http://docs.opscode.com/config_rb_knife.html for more information on knife configuration options

current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                "janedoe"
client_key               "#{current_dir}/janedoe.pem"
chef_server_url          "https://chef.gitlab.com/organizations/gitlab"
cache_type               'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )
cookbook_path            ["#{current_dir}/../cookbooks"]

knife[:vault_mode] = 'client'
knife[:ssh_user] = 'janedoe'
```
