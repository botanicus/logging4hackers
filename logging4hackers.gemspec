#!/usr/bin/env gem build
# encoding: utf-8

Gem::Specification.new do |s|
  s.name = 'logging4hackers'
  s.version = '0.0.1'
  s.authors = ['James C Russell aka botanicus']
  s.homepage = 'http://github.com/botanicus/logging4hackers'
  s.summary = 'Logging using AMQP, pipes, sockets, ZeroMQ ... you name it!'
  s.description = 'Any idiot can append to file. How about using AMQP? Pipes? ZeroMQ? Other cool shit??? Huh???'
  s.email = 'james@101ideas.cz'

  # Files.
  ignore_patterns = ['Gemfile.lock', /\.gem$/]

  s.files = begin
    (Dir.glob('**/*') - Dir.glob('doc/**/*')).
    select { |path| File.file?(path) }.
    delete_if do |file|
      ignore_patterns.any? do |pattern|
        file.match(pattern)
      end
    end
  end

  s.executables = Dir['bin/*'].map(&File.method(:basename))
  s.require_paths = ['lib']

  s.post_install_message = 'Bored. Wanna chat?'

  # RubyForge.
  s.rubyforge_project = 'logging4hackers'
end
