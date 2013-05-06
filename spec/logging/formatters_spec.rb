# encoding: utf-8

require 'spec_helper'

describe Logging::Formatters::Default do
  describe '#format_single_message' do
    let(:message) do
      subject.format_single_message(:info, 'logs.test.app', "Hello World!")
    end

    it "should combine identifier with log level" do
      pending "it's not including the log level yet" do
        message.should match('logs.test.app.info')
      end
    end

    it "should display timestamp" do
      message.should match(/\d{2}:\d{2}:\d{2}/)
    end

    it "should display the actual message" do
      message.should match("Hello World!")
    end
  end

  describe '#format_multiple_messages' do
    let(:message) do
      subject.format_multiple_messages(:info, 'logs.test.app', ["Hello", "World!"])
    end

    it "should combine identifier with log level" do
      pending "it's not including the log level yet" do
        message.should match('logs.test.app.info')
      end
    end

    it "should display timestamp" do
      message.should match(/\d{2}:\d{2}:\d{2}/)
    end

    it "should display the actual message" do
      message.should match("Hello\n  World!")
    end
  end
end

describe Logging::Formatters::JustMessage do
  describe '#format_single_message' do
    let(:message) do
      subject.format_single_message(:info, 'logs.test.app', "Hello World!")
    end

    it "should not display the identifier" do
      message.should_not match('logs.test.app')
    end

    it "should not display the log level" do
      message.should_not match('info')
    end

    it "should not display timestamp" do
      message.should_not match(/\d{2}:\d{2}:\d{2}/)
    end

    it "should display the actual message" do
      message.should eql("~ Hello World!")
    end
  end

  describe '#format_multiple_messages' do
    let(:message) do
      subject.format_multiple_messages(:info, 'logs.test.app', ["Hello", "World!"])
    end

    it "should not display the identifier" do
      message.should_not match('logs.test.app')
    end

    it "should not display the log level" do
      message.should_not match('info')
    end

    it "should not display timestamp" do
      pending "This obviously doesn't work now" do
        message.should_not match(/\d{2}:\d{2}:\d{2}/)
      end
    end

    it "should display the actual message" do
      message.should match("Hello\n  World!")
    end
  end
end

describe Logging::Formatters::Colourful do
  describe '#format_single_message' do
    let(:message) do
      subject.format_single_message(:info, 'logs.test.app', "Hello World!")
    end

    it "should combine identifier with log level" do
      pending "it's not including the log level yet" do
        message.should match('logs.test.app.info')
      end
    end

    it "should display timestamp" do
      message.should match(/\d{2}:\d{2}:\d{2}/)
    end

    it "should display the actual message" do
      message.should match("Hello World!")
    end
  end

  describe '#format_multiple_messages' do
    let(:message) do
      subject.format_multiple_messages(:info, 'logs.test.app', ["Hello", "World!"])
    end

    it "should combine identifier with log level" do
      pending "it's not including the log level yet" do
        message.should match('logs.test.app.info')
      end
    end

    it "should display timestamp" do
      message.should match(/\d{2}:\d{2}:\d{2}/)
    end

    it "should display the actual message" do
      message.should match("Hello\n  World!")
    end
  end
end
