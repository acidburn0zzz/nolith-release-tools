require 'colorize'
require 'dotenv'
Dotenv.load

$LOAD_PATH.unshift(File.expand_path('./lib', __dir__))

require 'version'
require 'project/gitlab_ce'
require 'project/gitlab_ee'
require 'project/omnibus_gitlab'
require 'local_repository'
require 'monthly_issue'
require 'patch_issue'
require 'branch'
require 'preparation_merge_request'
require 'merge_request'
require 'security_patch_issue'
require 'release/gitlab_ce_release'
require 'release/gitlab_ee_release'
require 'services/upstream_merge_service'
require 'shared_status'
require 'slack'
require 'sync'
require 'upstream_merge'
require 'upstream_merge_request'

unless ENV['CI'] || LocalRepository.ready?
  abort('Please use the master branch and make sure you are up to date.'.colorize(:red))
end
