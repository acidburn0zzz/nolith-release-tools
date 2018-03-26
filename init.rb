require 'colorize'
require 'dotenv'
Dotenv.load

$LOAD_PATH.unshift(File.expand_path('./lib', __dir__))

require 'version'
require 'project'
require 'pick_into_label'
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
require 'qa_issue'
