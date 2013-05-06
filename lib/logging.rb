# encoding: utf-8

# stream.logs.app.error
# stream.logs.db.*
# stream.logs.#
# stream.logs.*.error

require_relative 'logging/io'
require_relative 'logging/formatters'

module Logging
  class Logger
    LEVELS ||= [:error, :warn, :info]

    attr_reader :label
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
