# frozen_string_literal: true

module ReleaseTools
  module Slack
    class AutoDeployNotification < Webhook
      def self.webhook_url
        ENV.fetch('AUTO_DEPLOY_NOTIFICATION_URL')
      end

      def self.on_create(results)
        return unless results.any?

        branch = results.first.branch
        fallback = "New auto-deploy branch: `#{branch}`"

        blocks = [
          {
            type: 'section',
            text: mrkdwn(fallback)
          },
          {
            type: 'section',
            fields: results.map do |result|
              mrkdwn("<#{commits_url(result.project, branch)}|#{result.project}>")
            end
          }
        ]

        if ENV['CI_JOB_URL']
          blocks << {
            type: 'context',
            elements: [
              mrkdwn("Created via <#{ENV['CI_JOB_URL']}|scheduled pipeline>.")
            ]
          }
        end

        fire_hook(text: fallback, blocks: blocks)
      end

      def self.commits_url(project, branch)
        "https://gitlab.com/#{project}/commits/#{branch}"
      end
    end
  end
end
