#!/usr/bin/env ruby
# encoding: utf-8

require_relative 'lib/logging'
require_relative 'lib/logging/code'

# logger = Logging::Logger.new('testapp.logs.db')
#
# logger.info("Hello World!")
# logger.info("Just sayi' hi 'cause I'm gonna hang out here for a while")
# logger.info("No one up for a chat :/ ?")

=begin
logger = Logging::Logger.new do |logger|
  logger.io = Logging::IO::Pipe.new('testapp.logs.db', '/tmp/loggingd.pipe')
  logger.formatter = Logging::Formatters::Colourful.new
end

logger.info("App started")
logger.warn("I'm bored")
=end

__END__
require 'eventmachine'

EM.run do
  require 'amq/client'

  AMQ::Client.connect(adapter:  'eventmachine') do |connection|
    channel = AMQ::Client::Channel.new(connection, 1)

    channel.open

    exchange = AMQ::Client::Exchange.new(connection, channel, 'amq.topic', :topic)

    logger = Logging::Logger.new do |logger|
      logger.io = Logging::IO::AMQP.new('testapp.logs.db', exchange)
      logger.formatter = Logging::Formatters::Colourful.new
    end

    EM.add_periodic_timer(1) do
      level = Logging::Logger::LEVELS[rand(Logging::Logger::LEVELS.length)]
      logger.send(level, 'GET /ideas.json -- 20s')
      logger.inspect({method: 'GET', path: '/ideas.json', response: '200'}.to_json)
      logger.measure_time("Request took %s") do
        sleep 0.23
      end
      logger.inspect({method: 'GET', path: '/ideas.json', response: '200'})
    end

    EM.add_periodic_timer(2.3) do
      level = Logging::Logger::LEVELS[rand(Logging::Logger::LEVELS.length)]
      logger.send(level, 'line 1', 'line 2', 'line 3')
    end
  end
end
