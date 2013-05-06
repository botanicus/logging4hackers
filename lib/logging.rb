# encoding: utf-8

require_relative 'logging/io'
require_relative 'logging/formatters'

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

    # @example
    #   # Create logger with default values, specifying
    #   # only the label (mandatory when not specifying io).
    #   logger = Logging::Logger.new('logs.my_app.db')
    #
    # @example
    #   # Create a logger specifying a custom formatter and io.
    #   logger = Logging::Logger.new('logs.my_app.db') do |logger|
    #     logger.io = Logging::IO::Pipe.new(logger.label, '/var/mypipe')
    #     logger.formatter = Logging::Formatters::Colourful.new
    #   end
    def initialize(label = nil, &block)
      @label = label
      block.call(self) if block
    end

    attr_writer :io
    def io
      @io ||= begin
        if self.label
          IO::Raw.new(self.label)
        else
          raise "You have to provide label in Logger.new if you want to use the default io object!"
        end
      end
    end

    def write(*args)
      self.io.write(*args)
    end

    attr_writer :formatter
    def formatter
      @formatter ||= Formatters::Default.new
    end

    LEVELS.each do |level|
      define_method(level) do |*messages|
        log(level, *messages)
      end
    end

    def log(level, *messages)
      if messages.length == 1
        self.io.write_single_message(self.formatter, level, messages.first)
      else
        self.io.write_multiple_messages(self.formatter, level, messages)
      end
    end
  end
end
