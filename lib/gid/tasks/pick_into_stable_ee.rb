require_relative 'task'

module Gid
  module Tasks
    class PickIntoStableEe < Tasks::PickIntoStableCe
      private

      def project_id
        Config.ee_project_id
      end

      def repo
        Config.ee_repo
      end
    end
  end
end
