module Gid
  module Output
    class TaskList < Base
      def initialize(version)
        @version = version
        @running = nil
      end

      def to_s
        ([description] + tasks.keys).join("\n")
      end

      def tasks
        @tasks ||=
          begin
            {
              'Pick into stable CE' => Gid::Tasks::PickIntoStableCe.new(version: @version),
              'Pick into stable EE' => Gid::Tasks::PickIntoStableEe.new(version: @version)
            }
          end
      end

      def [](selected)
        @running = selected
        tasks.values[selected]
      end

      def running?
        @running
      end

      private

      def description
        'Task List'
      end
    end
  end
end
