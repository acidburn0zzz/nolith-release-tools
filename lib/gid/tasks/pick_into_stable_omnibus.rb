require_relative 'task'

module Gid
  module Tasks
    class PickIntoStableOmnibus < Tasks::PickIntoStableCe
      private

      def project_id
        Config.omnibus_project_id
      end

      def repo
        Config.omnibus_repo
      end

      def stable_branch
        @options[:version].stable_branch
      end
    end
  end
end
