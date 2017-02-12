module Gid
  module Output
    module Logger
      def self.write(string, mode = 'a')
        string = string.gsub(/\n/, "\n" + (' ' * 26))

        File.open(Config.log_file, mode) do |f|
          f.puts("[#{Time.now.utc}] " + string)
        end
      end

      def self.archive!
        if File.exist?(Config.log_file)
          File.open(Config.archive_log_file, 'a') do |f|
            f.puts(File.read(Config.log_file))
          end
        end

        write("New session. Old output appended to #{Config.archive_log_file}", 'w')
      end
    end
  end
end
