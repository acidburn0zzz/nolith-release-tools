module ReleaseTools
  module Release
    class CNGImageRelease < BaseRelease
      def remotes
        Project::CNGImage.remotes
      end

      private

      def execute_release
        if repository.tags.include?(tag)
          $stdout.puts "#{tag} already exists... Skipping...".colorize(:yellow)
          return
        end

        repository.ensure_branch_exists(stable_branch)
        push_ref('branch', stable_branch)
        push_ref('branch', 'master')
        create_tag(tag)
        push_ref('tag', tag)
      end
    end
  end
end
