#!/usr/bin/env ruby
# encoding: utf-8

# This expect to get data as Formatters::Serialised makes
# them, that means JSON with key for routing key and message
# for the formatted message.

require 'json'
require 'amq/client'
require 'eventmachine'

pipe_path = ARGV.first

class LogReader < EventMachine::FileWatch
  def initialize(exchange)
    @exchange = exchange
  end

  def notify_readable
    @io.readlines.each do |line|
      self.forward(line.chomp)
    end
  end

  def forward(line)
    data = self.parse(line)
    key, message = [data['key'], data['message']]
    @exchange.publish(message, key)
  rescue JSON::ParserError
    puts "Misformatted JSON: #{line.inspect}"
  end

  def parse(line)
    JSON.parse(line)
  end
end

# So far we assume single AMQP configuration (user/pass/host/vhost).
EM.run do
  AMQ::Client.connect(adapter: 'eventmachine') do |connection|
    # AMQP.
    channel = AMQ::Client::Channel.new(connection, 1)
    channel.open

    exchange = AMQ::Client::Exchange.new(connection, channel, 'amq.topic', :topic)

    # Pipe.
    fd = IO.sysopen(pipe_path, Fcntl::O_RDONLY|Fcntl::O_NONBLOCK)
    pipe = IO.new(fd, Fcntl::O_RDONLY|Fcntl::O_NONBLOCK)

    # Watch the pipe.
    fdmon = EM.watch(pipe, LogReader, exchange)
    fdmon.notify_readable = true
  end
end
