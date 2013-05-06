# encoding: utf-8

require_relative 'io'
require_relative 'formatters'

module Logging
  # Main class. Instantiate it to start logging.
  # In reality all this class does is to provide
  # convenience proxy to {file:lib/logging/io.rb io objects}
  # and {file:lib/logging/formatters.rb formatters}.
  class Logger
    # Log levels. At the moment adding new log levels
    # isn't supported. This might or might not change.
    LEVELS ||= [:error, :warn, :info]

    # Label is required only when you use the default
    # {file:lib/logging/io.rb io object}.
    attr_reader :label

    # Create a new logger.
    #
    # @param label [String, nil] Label. For instance `logs.myapp.db`.
    # @param block [Proc] Block with the newly created instance.
    #
    # @yield [logger] The logger instance which just has been created.
    #
    # @example
    #   # Create logger with default values, specifying
    #   # only the label (mandatory when not specifying io).
    #   logger = Logging::Logger.new('logs.my_app.db')
    #
    #   # Create a logger specifying a custom formatter and io.
    #   logger = Logging::Logger.new('logs.my_app.db') do |logger|
    #     logger.io = Logging::IO::Pipe.new(logger.label, '/var/mypipe')
    #     logger.formatter = Logging::Formatters::Colourful.new
    #   end
    def initialize(label = nil, &block)
      @label = label
      block.call(self) if block
    end

    # The cached io instance. If there's none, one will be created.
    #
    # @raise [RuntimeError] If the label isn't specified (when creating new deafult io).
    def io
      @io ||= begin
        if self.label
          IO::Raw.new(self.label)
        else
          raise "You have to provide label in Logger.new if you want to use the default io object!"
        end
      end
    end

    attr_writer :io

    # The cached formatter instance. If there's none, one will be created.
    def formatter
      @formatter ||= Formatters::Default.new
    end

    attr_writer :formatter

    # @!method error(*messages)
    #   Log an error message.
    #   @param messages [Array<#to_s>] Messages to be logged.
    #   @api public
    #
    # @!method warn(*messages)
    #   Log a warning message.
    #   @param messages [Array<#to_s>] Messages to be logged.
    #   @api public
    #
    # @!method info(*messages)
    #   Log an info message.
    #   @param messages [Array<#to_s>] Messages to be logged.
    #   @api public
    LEVELS.each do |level|
      define_method(level) do |*messages|
        log(level, *messages)
      end
    end

    # Underlaying function for logging any kind of message.
    # The actual functionality is delegated to {#io}.
    #
    # @param level [Symbol] Log level.
    # @param messages [Array<#to_s>] Messages to be logged.
    def log(level, *messages)
      if messages.length == 1
        self.io.write_single_message(self.formatter, level, messages.first)
      else
        self.io.write_multiple_messages(self.formatter, level, messages)
      end
    end

    # Delegate to `self.io#write.
    #
    # @param message [#to_s] Message to be written on the IO object.
    def write(message)
      self.io.write(message)
    end
  end
end
