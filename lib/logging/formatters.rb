# encoding: utf-8

module Logging
  module Formatters
    class Default
      FORMAT_STRINGS = {
        single: "%-5s %s -- %s",
        header: "%-5s %s"
      }

      def timestamp
        Time.now.strftime('%H:%M:%S')
      end

      def format_single_message(level, label, message, &block)
        args = [label, timestamp, message]
        args = block.call(*args) if block
        sprintf(self.class::FORMAT_STRINGS[:single], *args)
      end

      def format_multiple_messages(level, label, messages, &block)
        args = [level.to_s.upcase, timestamp]
        args = block.call(*args) if block

        header = sprintf(self.class::FORMAT_STRINGS[:header], *args)
        messages.unshift(nil)
        header + messages.join("\n  ")
      end
    end

    class JustMessage < Default
      # NOTE: Don't use ||=, otherwise it won't define it due its presence in superclass.
      FORMAT_STRINGS = {
        single: "~ %s",
        header: "~ %s"
      }

      def format_single_message(level, label, message)
        super(level, label, message) do |*args|
          [args.last]
        end
      end

      def format_multiple_messages(level, label, messages)
        super(level, label, messages) do |*args|
          [args.last]
        end
      end
    end

    class Colourful < Default
      LEVELS ||= {error: "\033[31m", warn: "\033[33m", info: "\033[36m", inspect: "\033[36m"}

      # NOTE: Don't use ||=, otherwise it won't define it due its presence in superclass.
      FORMAT_STRINGS = {
        single: "%s%-5s \033[37m%s\033[0m -- %s",
        header: "%s%-5s \033[37m%s\033[0m"
      }

      def format_single_message(level, label, message)
        super(level, label, message) do |*args|
          args.unshift(LEVELS[level])
        end
      end

      def format_multiple_messages(level, label, messages)
        super(level, label, messages) do |*args|
          args.unshift(LEVELS[level])
        end
      end
    end
  end
end
