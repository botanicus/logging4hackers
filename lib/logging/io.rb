# encoding: utf-8

require_relative 'formatters'

module Logging
  # IO objects define how to write the log message.
  # It can be on console, to a socket, to RabbitMQ,
  # named pipe ... you name it!
  module IO

    # @abstract
    #   Subclass and override {#write}.
    class Base
      attr_reader :label

      # @param label [String] Label. For instance `logs.app.db`.
      def initialize(label)
        @label = label
      end

      def write(message)
        raise NotImplementedError.new
      end
    end

    # Write on console.
    class Raw < Base
      def write(message)
        puts message
      end

      def write_single_message(formatter, level, message)
        self.write(formatter.format_single_message(level, self.label, message))
      end

      def write_multiple_messages(formatter, level, messages)
        self.write(formatter.format_multiple_messages(level, self.label, messages))
      end
    end

    # Discard everything.
    class Null < Raw
      def write(*)
      end
    end

    # Write to a file.
    class File < Raw
      attr_reader :path
      def initialize(label, path)
        @label, @path = label, path
      end

      def file
        @file ||= File.open(self.path, 'a')
      end

      def write(message)
        file.puts(message)
      end
    end

    # Write to a buffer.
    class Buffer < Raw
      def buffer
        @buffer ||= Array.new
      end

      def log(level, *messages)
        self.buffer << [level, messages]
      end

      def replay(io)
        self.buffer.each do |level, *messages|
          self.io.log(level, *messages)
        end
      end
    end

    # Write to a named pipe.
    class Pipe < Raw
      attr_reader :path
      def initialize(label, path)
        @label, @path = label, path
      end

      def pipe
        # The w+ means we don't block.
        @pipe ||= open(self.path, 'w+')
      end

      def write(message)
        self.pipe.puts(message)
        self.pipe.flush
      end
    end

    # Send message to an AMQP broker.
    class AMQP < Base
      def self.bootstrap(config)
        require 'amq/client'

        AMQ::Client.connect(config) do |connection|
          channel = AMQ::Client::Channel.new(connection, 1)

          channel.open

          exchange = AMQ::Client::Exchange.new(connection, channel, 'amq.topic', :topic)

          self.new(exchange)
        end
      end

      def initialize(label, exchange)
        @label, @exchange = label, exchange
      end

      def write_single_message(formatter, level, message)
        self.write(formatter.format_single_message(level, self.label, message), "#{self.label}.#{level}")
      end

      def write_multiple_messages(formatter, level, messages)
        self.write(formatter.format_multiple_messages(level, self.label, messages), "#{self.label}.#{level}")
      end

      def write(message, routing_key)
        @exchange.publish(message, routing_key)
      end
    end
  end
end
