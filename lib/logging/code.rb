# encoding: utf-8

require 'json'
require 'coderay'

module Logging
  class Logger
    # Inspect Ruby objects with syntax highlighting in JSON format.
    #
    # @overload inspect(*objects)
    #   @param objects [Array<#to_json>] List of objects for inspection.
    #
    # @overload inspect(label, *objects)
    #   @param label [String, Symbol] Label. For instance "Request time".
    #   @param objects [Array<#to_json>] List of objects for inspection.
    #
    # @example
    #   # Single object, no label.
    #   logger.inspect(path: "/", time: 0.0001)
    #
    #   # Single object with String label.
    #   logger.inspect("Request data", path: "/", time: 0.0001)
    #
    #   # Single object with Symbol label.
    #   logger.inspect(:request, {path: "/", time: 0.0001})
    #
    #   # Multiple objects, no label.
    #   logger.inspect({path: "/", time: 0.001}, {path: "/test"})
    #
    #   # Multiple objects with label.
    #   logger.inspect("Requests", {path: "/", time: 0.001}, {path: "/test"})
    #
    # @note
    #   This method is defined in {file:lib/logging/code.rb logging/code.rb}
    #   and requires {http://coderay.rubychan.de coderay}.
    #
    # @api public
    def inspect(*objects)
      label = ((objects.first.is_a?(String) ||
              objects.first.is_a?(Symbol)) &&
              objects.length > 1) ? objects.shift : nil

      code = objects.map do |object|
        begin
          json = JSON.generate(object, object_nl: ' ', array_nl: ' ', space: ' ')
          CodeRay.scan(json, :json).terminal
        rescue
          CodeRay.scan(object.inspect, :ruby).terminal
        end
      end.join("\n")

      self.log(:inspect, label ? "#{label}: #{code}" : code)
    end

    # Measure how long does it take to execute provided block.
    #
    # @param label [#%] Formatting string.
    # @param block [Proc] The block of which we'll measure the execution time.
    #
    # @example
    #   logger.measure_time("Request took %s") do
    #     sleep 0.1
    #   end
    #
    # @note
    #   This method is defined in {file:lib/logging/code.rb logging/code.rb}
    #   and requires {http://coderay.rubychan.de coderay}.
    #
    # @api public
    def measure_time(label, &block)
      before = Time.now.to_f; block.call
      self.info(label % (Time.now.to_f - before))
    end
  end
end

require_relative 'formatters'

Logging::Formatters::Colourful::LEVELS[:inspect] = "\033[36m"
