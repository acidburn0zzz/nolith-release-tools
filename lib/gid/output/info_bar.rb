module Gid
  module Output
    class InfoBar < Base
      def initialize(version)
        @version = version
      end

      def to_s
        "GitLab Release #{@version} - #{Time.now.utc} - Total time: #{lapse} - Current task: #{current_task}"
      end

      private

      def seconds
        (Time.now - start_time).to_i
      end

      def lapse
        Time.at(seconds).utc.strftime("%H:%M:%S")
      end

      def start_time
        @start_time ||= Time.now
      end

      def current_task
        # TODO
        lapse
      end
    end
  end
end
