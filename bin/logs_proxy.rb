#!/usr/bin/env ruby
# encoding: utf-8

$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))

require 'eventmachine'
require 'logging/logger'

begin
  require 'em/filetail'
rescue LoadError
  abort 'Make sure you have eventmachine-tail installed!'
end

# Usage:
#   ./bin/logs_proxy.rb [pipe path] *[key:path]
#
# Pipe path:
#   Path to the named path where to write new stuff which appears in logs.
#
# Key:path:
#   List of routing key: path where routing key is where we want to route changes in given path.
#   Path can be either a single file or a directory.
#   Example: logs.system.mysql:/var/log/mysql.log

PIPE_PATH = ARGV.shift
ITEMS = ARGV.reduce(Hash.new) do |buffer, item|
  key, path = item.split(':')

  # This is not perfect, it assumes the won't be any new files, but for now ...
  if File.directory?(path)
    buffer.merge(key => Dir.glob("#{path}/**/*.log"))
  else
    buffer.merge(key => [path])
  end
end

EM.run do
  puts "~ Logging into #{PIPE_PATH} ..."

  ITEMS.each do |routing_key, paths|
    logger = begin
      Logging::Logger.new do |logger|
        logger.io = Logging::IO::Pipe.new(routing_key, PIPE_PATH)
        logger.formatter = Logging::Formatters::Serialised.new(Logging::Formatters::JustMessage.new)
      end
    end

    # ???
    # logger.io.pipe.flock(File::LOCK_UN)

    paths.each do |path|
      puts "~ #{routing_key}: #{path}"

      EM.file_tail(path) do |tail, line|
        # When loggingd.rb doesn't run, it works
        # (checked through tail -f /var/run/loggingd.pipe)
        # However when loggingd.rb runs, the results don't
        # get flushed until logs_proxy.rb terminates.
        #
        # It might be just inotify not sending the notification?
        #
        # Currently loggingd.rb seems to be broken :/
        #
        # logger.info(line)
        logger.io.pipe.puts(logger.formatter.format_single_message('info', routing_key, line))
        logger.io.pipe.flush
      end
    end
  end
end
