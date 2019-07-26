# frozen_string_literal: true

require 'semantic_logger'

module ReleaseTools
  include ::SemanticLogger::Loggable

  module Logger
    # Remove process info from the default Color formatter
    class NoProcessColorFormatter < SemanticLogger::Formatters::Color
      def process_info
        nil
      end
    end

    # Remove process info from the Default formatter
    class NoProcessDefaultFormatter < SemanticLogger::Formatters::Default
      def process_info
        nil
      end
    end
  end
end

SemanticLogger.application = 'release-tools'
SemanticLogger.default_level = ENV.fetch('LOG_LEVEL', 'debug').to_sym

if File.basename($PROGRAM_NAME) == 'rspec'
  # Overwrite each test run; meaningless in CI but nice for development
  SemanticLogger.add_appender(
    io: File.new('log/test.log', 'w'),
    formatter: ReleaseTools::Logger::NoProcessDefaultFormatter.new
  )
else
  SemanticLogger.add_appender(
    io: $stdout,
    formatter: ReleaseTools::Logger::NoProcessColorFormatter.new
  )
end
