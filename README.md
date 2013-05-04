# About

In the Ruby community it's very popular to just append to a file in `log/` directory in the current app. Usually the developer can't even change the file. Damn it guys, we can do better!

* You might want to have the log files in `/var/log` for simpler **logrotate configuration**.
* You might not want to use files for logging at all. Especially considering that for **security reasons** it's better to send logs to a different server.
* You might want to **aggregate logs** from multiple servers.

## Readable Logs

Besides, logs should be easy to read for the developers. No unnecessary crap, red for errors, yellow for warnings, cyan for info. Show time and identifier (for instance `testapp.logs.db`) and the message. Easy peasy!

<img src="https://raw.github.com/botanicus/logging4hackers/master/logger.png" />

# Use-Cases

## Logging Straight Into RabbitMQ

*TODO: Disconnect the AMQP, stop EM & terminate.*

```ruby
require 'logging'
require 'logging/code'
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

    logger.info('Starting the app.')
    logger.inspect({method: 'GET', path: '/ideas.json', response: '200'})
    logger.error('Whops, no app defined, terminating.')
  end
end
```

## Client/Server

* You might not want to run EventMachine.
* Setting up the Pipe logger on the client side requires much less setup, hence much less stuff can wrong.
* The `loggingd.rb` script is a middleware, it can be changed to do some extra stuff at any time, send logs elsewhere etc which makes sense especially if you're using it for more applications.

```shell
# Create a named pipe.
mkfifo /tmp/loggingd.pipe

# Listen for messages coming to /tmp/loggingd.pipe.
# You probably want to write a script of your own
# which resends these messages onto RabbitMQ running
# on a different server.
./bin/logs_listen.rb /tmp/loggingd.pipe
```

```ruby
logger = Logging::Logger.new do |logger|
  logger.io = Logging::IO::Pipe.new('testapp.logs.db', '/tmp/loggingd.pipe')
  logger.io.formatter = Logging::Formatters::Colourful.new
end
```

# CLI
