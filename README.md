# About

In the Ruby community it's very popular to just append to a file in `log/` directory in the current app. In many frameworks the developer can't even change the file. Damn it guys, we can do better!

## `$ whoami`

![botanicus](http://www.gravatar.com/avatar/74c419a50563fa9e5044820c2697ffd6)
I'm a **launch-addict**, creating stuff that matters is my biggest passion. I **dropped out of high school** and learnt programming before I'd end up on a street. In just a few months I moved from <abbr title="Small town in mountains of Czech Republic">middle of nowhere</abbr> to **London** where I worked as a freelancer for do companies like **VMware** on the **RabbitMQ team** for which I <abbr title="Michael wasn't employed by VMware, he was hacking on AMQP in his free time. Kudos!">alongside</abbr> great hacker [michaelklishin](https://github.com/michaelklishin) rewrote the [AMQP gem](https://github.com/ruby-amqp/amqp).

I **contributed to many famous OSS projects** including **RubyGems**, **rSpec** and back in the g'd old days also to **Merb**. When EY decided to <abbr title="The so-called merge ... bunch of crap!">abandon Merb</abbr> I wrote my own web framework, [Rango](http://www.rubyinside.com/rango-ruby-web-app-framework-2858.html) (now <abbr title="Rango isn't maintained anymore. These days my apps are API servers with heavy JS frontend.">discontinued</abbr>), the only framework in Ruby with [template inheritance](https://github.com/botanicus/template-inheritance).

My only goal for this year is to launch a successful start-up. Could [MatcherApp](http://www.matcherapp.com) be it?

Follow my progress on [Twitter](https://twitter.com/botanicus) and make sure to read my [my blog](http://blog.101ideas.cz) (grab the [RSS](http://blog.101ideas.cz/posts.rss)).

## Advantages

* You might want to have the log files in `/var/log` for simpler **log rotation**.
* You might not want to use files for logging at all. Not on the app server anyway. Especially considering that for **security reasons** it's better to send logs to a different server.
* You might want to **aggregate logs** from multiple servers.
* You might want to **filter logs** based on given pattern. Give me all error messages from all applications `logs.#.error`, all log items for database layer of testapp `logs.testapp.db.*`, all error messages for testapp `logs.testapp.*.error` etc.
* Isn't ssh & tail -f really, really, I mean **really** lame? With AMQP, just subscribe to any pattern on any server you want from comfort of your own dev machine. Rock'n'roll!

## Readable Logs

Besides, logs should be easy to read for the developers. No unnecessary crap, red for errors, yellow for warnings, cyan for info. Show time and identifier (for instance `testapp.logs.db`) and the message. Easy peasy!

<img src="https://raw.github.com/botanicus/logging4hackers/master/logger.png" />

# Use-Cases

## Logging Into RabbitMQ (Local or Remote)

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

## Client/Server on Localhost using Named Pipe

* You might not want to run EventMachine.
* Setting up the Pipe logger on the client side requires much less setup, hence much less stuff can wrong.
* The `loggingd.rb` script is a middleware, it can be changed to do some extra stuff at any time, send logs elsewhere etc which makes sense especially if you're using it for more applications.

```bash
# Create a named pipe.
mkfifo /tmp/loggingd.pipe

# Listen for messages coming to /tmp/loggingd.pipe.
./bin/logs_listen.rb /tmp/loggingd.pipe
```

```ruby
logger = Logging::Logger.new do |logger|
  logger.io = Logging::IO::Pipe.new('testapp.logs.db', '/tmp/loggingd.pipe')
  logger.formatter = Logging::Formatters::Colourful.new
end
```

## Inspecting Remote Server

_Parsing of AMQP URL isn't implemented yet, but this is how it is going to work._

Often you want to figure out what's going on on your stagging server. This is how you do it:

```bash
./bin/logs_listen.rb 'logs.myapp.#' amqp://user:pass@remote_server/vhost
```

It creates temporary queue which it binds to the `amq.topic` exchange which exists by default in any RabbitMQ installation. Then it binds the temporary queue to this exchange with pattern we provide (in this case it's `logs.myapp.#`). This makes sure all the subscribers gets all the messages they're interested in.

# Logging Best Practices

## Don't Use Just One Logger Per App

Database, web server, application code, metrics, all in one place?

Why? Filtering based on specific pattern.

```ruby
class DB
  def self.logger
    @logger ||= Logging::Logger.new do |logger|
      logger.io = Logging::IO::Pipe.new('testapp.logs.db', '/tmp/loggingd.pipe')
      logger.formatter = Logging::Formatters::Colourful.new
    end
  end
end

class App
  def self.logger
  @logger ||= Logging::Logger.new do |logger|
    logger.io = Logging::IO::Pipe.new('testapp.app.db', '/tmp/loggingd.pipe')
    logger.formatter = Logging::Formatters::Colourful.new
  end
end

# Etc.
```

# Contributing

Feature branches, follow code conventions, docs & specs.
