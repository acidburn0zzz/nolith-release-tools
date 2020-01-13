# frozen_string_literal: true

module ReleaseTools
  module Release
    class GitlabEeRelease < GitlabCeRelease
      private

      def remotes
        Project::GitlabEe.remotes
      end
    end
  end
end
