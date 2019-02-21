# frozen_string_literal: true

module ReleaseTools
  module CherryPick
    # "Post" comments to the console rather than the GitLab API
    #
    # This notifier is useful for debugging or dry-run purposes.
    class ConsoleNotifier < CommentNotifier
      private

      def client
        ConsoleClient
      end

      class ConsoleClient
        def self.create_merge_request_comment(project_id, iid, comment)
          $stdout.puts "--> Adding the following comment to #{project_id}!#{iid}:"
          $stdout.puts comment.indent(4)
          $stdout.puts
        end
      end
    end
  end
end
