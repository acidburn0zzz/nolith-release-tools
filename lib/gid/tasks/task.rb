require 'dotenv'
require 'gitlab'

# Load ENV and then reset Gitlab client so it actually picks up our config
Dotenv.load
Gitlab.reset

module Gid
  module Tasks
    class Task
      attr_reader :status

      def initialize(options)
        @options = options

        # Empty: Not started
        # R: Running
        # F: Finished
        # E: Error
        @status = ''
      end

      def run!
        @status = 'R'

        Thread.new do
          begin
            run

            @status = 'F'
            Output::Logger.write(class_name + ' done!')
          rescue => e
            @status = 'E'

            Output::Logger.write(e.message)
            Output::Logger.write(e.backtrace.join("\n"))
          end
        end
      end

      protected

      def class_name
        self.class.name.split('::').last.gsub!(/([a-z\d])([A-Z])/, '\1 \2')
      end

      def run
        raise NotImplementedError
      end
    end
  end
end
