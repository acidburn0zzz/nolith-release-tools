module Slack
  autoload :Channel,                   'slack/channel'
  autoload :ChatopsNotification,       'slack/chatops_notification'
  autoload :TagNotification,           'slack/tag_notification'
  autoload :UpstreamMergeNotification, 'slack/upstream_merge_notification'
  autoload :Webhook,                   'slack/webhook'
end
