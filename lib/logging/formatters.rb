# encoding: utf-8

module Logging
  module Formatters

    # Default formatter. No colours, just log level, time stamp,
    # label and the actual log message.
    class Default
      # Format strings.
      #
      # The `single` key is used by {#format_single_message},
      # whereas `header` is used by {#format_multiple_messages}.
      FORMAT_STRINGS = {
        single: '%-5s %s -- %s',
        header: '%-5s %s'
      }

      # Format single log message.
      #
      # @param level [Symbol] Log level.
      # @param label [String] Identifier, for instance logs.app.db.
      # @param message [#to_s] The actual log message.
      #
      # @return [String] The log message.
      #
      # @see `FORMAT_STRINGS[:single]`
      #
      # @api plugin.
      #
      # @todo
      #   There's no documentation for the block yet, it's being
      #   used only for extending functionality from the subclasses.
      #   It should be probably refactored, otherwise it will get
      #   proper documentation.
      def format_single_message(level, label, message, &block)
        args = [label, timestamp, message]
        args = block.call(*args) if block
        sprintf(self.class::FORMAT_STRINGS[:single], *args)
      end

      # Format multiple log messages.
      #
      # @param level [Symbol] Log level.
      # @param label [String] Identifier, for instance logs.app.db.
      # @param messages [Array<#to_s>] The actual messages.
      #
      # @return [String] The log message.
      #
      # @see `FORMAT_STRINGS[:header]`
      #
      # @api plugin.
      #
      # @todo
      #   There's no documentation for the block yet, it's being
      #   used only for extending functionality from the subclasses.
      #   It should be probably refactored, otherwise it will get
      #   proper documentation.
      def format_multiple_messages(level, label, messages, &block)
        args = [level.to_s.upcase, timestamp]
        args = block.call(*args) if block

        header = sprintf(self.class::FORMAT_STRINGS[:header], *args)
        messages.unshift(nil)
        header + messages.join("\n  ")
      end

      protected

      # @api protected
      def timestamp
        Time.now.strftime('%H:%M:%S')
      end
    end

    # This is useful for logging on console.
    class JustMessage < Default
      # The `single` key is used by {#format_single_message},
      # whereas `header` is used by {#format_multiple_messages}.
      FORMAT_STRINGS = {
        single: "~ %s",
        header: "~ %s"
      }

      # Format single log message.
      #
      # @param level [Symbol] Log level.
      # @param label [String] Identifier, for instance logs.app.db.
      # @param message [#to_s] The actual log message.
      #
      # @return [String] The log message.
      #
      # @see `FORMAT_STRINGS[:single]`
      #
      # @api plugin.
      def format_single_message(level, label, message)
        super(level, label, message) do |*args|
          [args.last]
        end
      end

      # Format multiple log messages.
      #
      # @param level [Symbol] Log level.
      # @param label [String] Identifier, for instance logs.app.db.
      # @param messages [Array<#to_s>] The actual messages.
      #
      # @return [String] The log message.
      #
      # @see `FORMAT_STRINGS[:header]`
      #
      # @api plugin.
      def format_multiple_messages(level, label, messages)
        super(level, label, messages) do |*args|
          [args.last]
        end
      end
    end

    class Colourful < Default
      # Colours for each log level.
      LEVELS ||= {error: "\033[31m", warn: "\033[33m", info: "\033[36m"}

      # The `single` key is used by {#format_single_message},
      # whereas `header` is used by {#format_multiple_messages}.
      FORMAT_STRINGS = {
        single: "%s%-5s \033[37m%s\033[0m -- %s",
        header: "%s%-5s \033[37m%s\033[0m"
      }

      # Format single log message.
      #
      # @param level [Symbol] Log level.
      # @param label [String] Identifier, for instance logs.app.db.
      # @param message [#to_s] The actual log message.
      #
      # @return [String] The log message.
      #
      # @see `FORMAT_STRINGS[:single]`
      #
      # @api plugin.
      def format_single_message(level, label, message)
        super(level, label, message) do |*args|
          args.unshift(LEVELS[level])
        end
      end

      # Format multiple log messages.
      #
      # @param level [Symbol] Log level.
      # @param label [String] Identifier, for instance logs.app.db.
      # @param messages [Array<#to_s>] The actual messages.
      #
      # @return [String] The log message.
      #
      # @see `FORMAT_STRINGS[:header]`
      #
      # @api plugin.
      def format_multiple_messages(level, label, messages)
        super(level, label, messages) do |*args|
          args.unshift(LEVELS[level])
        end
      end
    end
  end
end
