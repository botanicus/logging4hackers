# encoding: utf-8

require 'spec_helper'

describe Logging::Logger do
  it "should add colour for inspect" do
    Logging::Formatters::Colourful::LEVELS.should include(:inspect)
  end

  subject do
    described_class.new('logs.my_app.db') do |logger|
      logger.io = TestIO.new(logger.label)
      logger.formatter = Logging::Formatters::JustMessage.new
    end
  end

  def strip_escape_sequences(data)
    data.gsub(/\e\[\d+(;\d+)?m/, '')
  end

  describe '#inspect' do
    context 'with label' do
      it "should use first string as the label if there's more than one argument" do
        subject.inspect('Request data', path: '/')
        message = strip_escape_sequences(subject.io.messages.last)
        message.should eql('~ Request data: { "path": "/" }')
      end

      it "should use first symbol as the label if there's more than one argument" do
        subject.inspect(:request, path: '/')
        message = strip_escape_sequences(subject.io.messages.last)
        message.should eql('~ request: { "path": "/" }')
      end
    end

    context 'without label' do
      it "should just inspect the string if it's the only argument" do
        subject.inspect("Hello\nWorld!")
        message = strip_escape_sequences(subject.io.messages.last)
        message.should eql('~ "Hello\nWorld!"')
      end

      it "should inspect all arguments" do
        subject.inspect({path: '/'}, {path: '/test'})

        message  = strip_escape_sequences(subject.io.messages.last)
        expected = ['~ ', '{ "path": "/" }', "\n", '{ "path": "/test" }']

        message.should eql(expected.join)
      end
    end
  end

  describe '#measure_time' do
    it "should measure how long it takes to execute its block"
    it "should report using label provided as the first argument"
  end
end
