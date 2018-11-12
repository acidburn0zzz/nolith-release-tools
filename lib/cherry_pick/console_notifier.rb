require 'stringio'
require 'active_support/core_ext/string/indent'

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
      def self.create_merge_request_comment(project, iid, comment)
        $stdout.puts "--> Adding the following comment to #{project}!#{iid}:"
        $stdout.puts comment.indent(4)
        $stdout.puts
      end
    end
  end
end
