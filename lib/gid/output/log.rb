module Gid
  module Output
    class Log < Base
      TOP_MARGIN = 10

      # TODO: Use initializer instead

      def to_s(max_lines)
        description + log(max_lines)
      end

      def log(max_lines)
        last_lines = max_lines - TOP_MARGIN

        chunk = Open3.popen3("tail -#{last_lines} #{Config.log_file}") do |_i, o, _e, _t|
          o.read.chomp
        end

        chunk + ("\n" * (last_lines - chunk.lines.size))
      end

      private

      def description
        "Output Log: \n"
      end
    end
  end
end
