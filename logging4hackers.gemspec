#!/usr/bin/env gem build
# encoding: utf-8

Gem::Specification.new do |s|
  s.name = 'logging4hackers'
  s.version = '0.0.1'
  s.authors = ['James C Russell']
  s.homepage = 'http://github.com/botanicus/logging4hackers'
  s.summary = 'Logging using AMQP, pipes, sockets, ZeroMQ ... you name it!'
  s.description = 'Any idiot can append to file. How about using AMQP? Pipes? ZeroMQ? Other cool shit??? Huh???'
  s.email = 'james@101ideas.cz'

  # Files.
  s.files = Array.new.tap do |files|
    files << Dir.glob('bin/*')
    files << Dir.glob('lib/*')
    files << ['README.md', __FILE__]
  end.flatten

  s.executables = Dir['bin/*'].map(&File.method(:basename))
  s.default_executable = 'logs_listen.rb'
  s.require_paths = ['lib']

  s.post_install_message = 'Bored. Wanna chat?'

  # RubyForge.
  s.rubyforge_project = 'logging4hackers'
end
