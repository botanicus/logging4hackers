#!/usr/bin/env ruby
# encoding: utf-8

require 'eventmachine'
require 'amq/client'

# Usage:
#   ./bin/logs_listen.rb [routing key] [AMQP URI] [log dir]
#
# Routing Key Examples:
#   myapp.logs.*.error
#   myapp.logs.db.*
#   myapp.logs.#
#
# AMQP URI:
#   For instance amqp://user:pass@host/vhost
#   See http://www.rabbitmq.com/uri-spec.html
#
# Log Directory (TBD):
#   If the log directory is specified, messages will be saved into files.
#   For example when specifying /var/log as my log directory, then when
#   I'll get message with routing key myapp.logs.db.error, it will be
#   written into /var/log/myapp.db.log.

# ARGV parsing.
routing_key   = ARGV.first || '#.logs.#'
log_directory = ARGV[2]
amqp_opts = if ARGV[1]
  puts "~ AMQP: #{AMQ::Client::Settings.parse_amqp_url(ARGV[1])}"
  AMQ::Client::Settings.parse_amqp_url(ARGV[1]).merge(adapter: 'eventmachine')
else
  {adapter: 'eventmachine'}
end

EM.run do
  AMQ::Client.connect(amqp_opts) do |connection|

    channel = AMQ::Client::Channel.new(connection, 1)
    channel.open

    queue = AMQ::Client::Queue.new(connection, channel)

    queue.declare(false, false, false, true) do
      puts "~ Creating autodeletable queue."
    end

    exchange = AMQ::Client::Exchange.new(connection, channel, 'amq.topic', :topic)

    queue.bind(exchange.name, routing_key) do |frame|
      puts "~ Binding it to the amq.topic exchange with routing key #{routing_key}."
    end

    queue.consume(true) do |consume_ok|
      puts "~ Listening for messages ..."

      queue.on_delivery do |basic_deliver, header, payload|
        if log_directory
          # basic_deliver.routing_key
        else
          puts payload
        end
      end
    end
  end
end
