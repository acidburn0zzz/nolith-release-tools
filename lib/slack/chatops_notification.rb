# frozen_string_literal: true

module Slack
  class ChatopsNotification < Webhook
    DEFAULT_CHANNEL = 'C8PKBH3M5' # announcements

    def self.channel
      ENV.fetch('CHAT_CHANNEL', DEFAULT_CHANNEL)
    end

    def self.job_url
      ENV.fetch('CI_JOB_URL', 'https://example.com/')
    end

    def self.task
      ENV.fetch('TASK', '')
    end

    def self.webhook_url
      ENV.fetch('SLACK_CHATOPS_URL')
    end

    def self.release_issue(issue)
      return unless task.present?

      text = "The `#{task}` command at #{job_url} completed!"
      attachment = {
        fallback: '',
        color: issue.status == :created ? 'success' : 'warning',
        title: issue.title,
        title_link: issue.url
      }

      fire_hook(text: text, attachments: [attachment], channel: channel)
    end
  end
end
