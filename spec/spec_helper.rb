# encoding: utf-8

require 'logging'

class TestIO < Logging::IO::Base
  def write(message)
    self.messages << message
  end

  def messages
    @messages ||= Array.new
  end

  def write_single_message(formatter, level, message)
    self.write(formatter.format_single_message(level, self.label, message))
  end

  def write_multiple_messages(formatter, level, messages)
    self.write(formatter.format_multiple_messages(level, self.label, messages))
  end
end
