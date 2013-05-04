# encoding: utf-8

require 'json'
require 'coderay'

module Logging
  class Logger
    # Inspect Ruby objects.
    def inspect(*objects)
      # Label.
      label = (objects.first.is_a?(String) || objects.first.is_a?(Symbol)) ? objects.shift : nil

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

    def measure_time(message, &block)
      before = Time.now.to_f; block.call
      self.info(message % (Time.now.to_f - before))
    end
  end
end
