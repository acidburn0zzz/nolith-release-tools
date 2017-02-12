module Gid
  module Output
    class HelpBar < Base
      def to_s(key)
        "#{default_message}#{key_output[key.downcase.to_sym]}"
      end

      def default_message_length
        @default_message_length ||= default_message.size
      end

      private

      def default_message
        " \u21B5 (Start/Resume Step) \u21C5 (Select step) A (Auto-mode) C-x (Exit) "
      end

      def key_output
        @key_output ||=
          {
            enter: 'Starting new task!',
            a: 'Not implemented yet :(',
            e: 'ERROR',
            r: 'Task running...',
            f: 'Task finished!'
          }
      end
    end
  end
end
