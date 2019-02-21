# frozen_string_literal: true
# frozen_string_literal: true

module ReleaseTools
  module Slack
    class ChatopsNotification < Webhook
      def self.channel
        ENV.fetch('CHAT_CHANNEL', nil)
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
          color: issue.status == :created ? 'good' : 'warning',
          title: issue.title,
          title_link: issue.url
        }

        fire_hook(text: text, attachments: [attachment], channel: channel)
      end
    end
  end
end
