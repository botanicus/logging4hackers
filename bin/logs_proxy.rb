#!/usr/bin/env ruby
# encoding: utf-8

$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))

require 'eventmachine'
require 'logging/logger'

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

class LogReader < EventMachine::FileWatch
  def initialize(logger)
    @logger = logger
  end

  def notify_readable
    @io.readlines.each do |line|
      @logger.info(line)
    end
  end
end

EM.run do
  ITEMS.each do |routing_key, paths|
    logger = begin
      Logging::Logger.new do |logger|
        logger.io = Logging::IO::Pipe.new(routing_key, PIPE_PATH)
        logger.formatter = Logging::Formatters::Serialised.new(Logging::Formatters::JustMessage.new)
      end
    end

    paths.each do |path|
      puts "~ #{routing_key}: #{path}"
      # Log file.
      fd = IO.sysopen(path, Fcntl::O_RDONLY|Fcntl::O_NONBLOCK)
      file = IO.new(fd, Fcntl::O_RDONLY|Fcntl::O_NONBLOCK)

      # Watch the file.
      fdmon = EM.watch(file, LogReader, logger)
      fdmon.notify_readable = true
    end
  end
end
