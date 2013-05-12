# About [![Travis CI](https://travis-ci.org/botanicus/logging4hackers.png)](https://travis-ci.org/botanicus/logging4hackers)

In the Ruby community it's very popular to **just append** to a file in `log/` directory in the current app. In many frameworks the developer **can't even change** the file. Damn it guys, **we can do better**!

## Why Should I Care?

* You might want to have the log files in `/var/log` for simpler **log rotation**.
* You might **not want to use files** for logging at all. Not on the app server anyway. Especially considering that for **security reasons** it's better to send logs to a different server.
* You might want to **aggregate logs** from multiple servers.
* You might want to **filter logs** based on given pattern. Give me all error messages from all applications `logs.#.error`, all log items for database layer of testapp `logs.testapp.db.*`, all error messages for testapp `logs.testapp.*.error` etc.
* Isn't ssh & tail -f really, really, I mean **really** lame? With AMQP, just [subscribe to any pattern](#inspecting-remote-server) on any server you want from **comfort of your own dev machine**. Rock'n'roll!

## Readable Logs (If You Want)

Besides, logs should be easy to read for the developers. That's why logging4hackers provides [colourful formatter](http://rubydoc.info/github/botanicus/logging4hackers/master/Logging/Formatters/Colourful) which uses colours instead of displaying log level as text and [Logger#inspect](http://rubydoc.info/github/botanicus/logging4hackers/master/Logging/Logger#inspect-instance_method) for showing objects as syntax-highlighted JSON.

<img src="https://raw.github.com/botanicus/logging4hackers/master/logger.png" />

```ruby
require 'logging'
require 'logging/code'

logger = Logging::Logger.new do |logger|
  logger.io = Logging::IO::Raw.new('testapp.logs.db')
  logger.formatter = Logging::Formatters::Colourful.new
end

logger.info("Starting the app.")
logger.inspect({method: 'GET', path: '/ideas.json', response: '200'})
logger.warn("Now I'm a tad bored ...")
logger.error("OK, gotta sleep now.")
```

*Note: Actually the screenshot shows how would you inspect messages published into RabbitMQ, whereas in the code I'm using the `IO::Raw` which only prints to console. [Example with AMQP](#logging-into-rabbitmq-local-or-remote) is longer.*

## About [@botanicus](https://twitter.com/botanicus) ([blog](http://blog.101ideas.cz))

![botanicus](http://www.gravatar.com/avatar/74c419a50563fa9e5044820c2697ffd6)
I'm a **launch-addict**, creating stuff that matters is my biggest passion. I **dropped out of high school** and learnt programming before I'd end up on a street. In just a few months I moved from <a title="Small town in mountains of Czech Republic">middle of nowhere</a> to **London** where I worked as a freelancer for companies like **VMware** on the **RabbitMQ team** for which I, <a title="Michael wasn't employed by VMware, he was hacking on AMQP in his free time. Kudos!">alongside</a> great hacker [michaelklishin](https://github.com/michaelklishin), rewrote the [AMQP gem](https://github.com/ruby-amqp/amqp).

I **contributed** to many famous OSS projects including **RubyGems**, **rSpec** and back in the g'd old days also to **Merb**. When EY decided to <a title="The so-called merge ... bunch of crap!">abandon Merb</a> I wrote my own web framework, [Rango](http://www.rubyinside.com/rango-ruby-web-app-framework-2858.html) (now <a title="These days my apps are API servers with heavy JS frontend.">discontinued</a>), the only framework in Ruby with [template inheritance](https://github.com/botanicus/template-inheritance).

My other hobbies include **travelling**, learning **languages** (你好!) and **personal development**. My [3 + 2 rule](http://lifehacker.com/5853732/take-a-more-realistic-approach-to-your-to+do-list-with-the-3-%252B-2-rule) was featured on LifeHacker.

My only goal for this year is to **launch a successful start-up**. Could [MatcherApp](http://www.matcherapp.com) be it?

# Use-Cases

### Logging Into RabbitMQ (Local or Remote)

*TODO: Disconnect the AMQP, stop EM & terminate.*

* You can connect to RabbitMQ on **localhost** or **remote server**.
* So far it requires **some setup**. In the future I might **provide helpers** for this.
* It's the **most powerful** setup. You can **filter patterns**, you can **discard messages** just by **not subscribing** to those you're not interested in, you can **consume** given message **multiple times**, so you can for instance **duplicate logs** on two servers etc.
* Instead writing directly to AMQP you can **write to a named pipe** and have a **daemon** which **reroutes messages** to RabbitMQ as described [below](#clientserver-on-localhost-using-named-pipe).

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

### Client/Server on Localhost using Named Pipe

* You **might not** want to **run EventMachine**.
* Setting up the Pipe logger on the client side requires **much less setup**, hence **much less stuff can wrong**.
* It's easy to write a daemon to **publish those messages** from the pipe **into RabbitMQ**. In the future I might provide one.

```bash
# Create a named pipe.
mkfifo /tmp/loggingd.pipe

# Listen for messages coming to /tmp/loggingd.pipe.
#tail -f /tmp/loggingd.pipe

# Listen for new messages on the pipe and forward them to RabbitMQ.
./bin/loggingd.rb
```

```ruby
logger = Logging::Logger.new do |logger|
  logger.io = Logging::IO::Pipe.new('testapp.logs.db', '/tmp/loggingd.pipe')
  logger.formatter = Logging::Formatters::Serialised.new(Logging::Formatters::Colourful.new)
end
```

# Inspecting Remote Server

Often you want to figure out **what's going on on server**. This is how you do it:

```bash
./bin/logs_listen.rb 'logs.myapp.#' amqp://user:pass@remote_server/vhost
```

It creates temporary queue which it binds to the `amq.topic` exchange which exists by default in any RabbitMQ installation. Then it binds the temporary queue to this exchange with pattern we provide (in this case it's `logs.myapp.#`). This makes sure all the subscribers gets all the messages they're interested in.

# Logging Best Practices

### Don't Use Just One Logger Per App

In Ruby community people **often don't use loggers** at all. If they do, they work with **only one instance**. One logger instance for database, web server, application code and metrics. That **doesn't scale**.

If you use one logger instance per each module you can very easily **filter** based on **specific pattern**.

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
```

# Links

* [YARD API Documentation](http://rubydoc.info/github/botanicus/logging4hackers/master)
* [Semantic Versioning](http://semver.org)
