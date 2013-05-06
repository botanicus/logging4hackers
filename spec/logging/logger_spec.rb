# encoding: utf-8

require 'spec_helper'

describe Logging::Logger do
  it "should define log levels" do
    described_class::LEVELS.should include(:error)
    described_class::LEVELS.should include(:warn)
    described_class::LEVELS.should include(:info)
  end

  describe ".new" do
    it "should create a new instance when no arguments are given" do
      described_class.new.should be_kind_of(described_class)
    end

    it "should optionally take label" do
      instance = described_class.new('logs.my_app.db')
      instance.label.should eql('logs.my_app.db')
    end

    it "should create a new instance and yield the instance into a block" do
      described_class.new { |logger| @instance = logger}
      @instance.should be_kind_of(described_class)
    end
  end

  context "instance methods" do
    subject do
      described_class.new('logs.my_app.db')
    end

    describe "#io" do
      it "should have sensible default" do
        subject.io.should be_kind_of(Logging::IO::Raw)
      end

      it "should fail if label isn't provided" do
        expect { described_class.new.io }.to raise_error
      end

      it "should be writable" do
        expect { subject.io = TestIO.new('label') }.not_to raise_error
      end
    end

    describe "#formatter" do
      it "should have sensible default" do
        subject.formatter.should be_kind_of(Logging::Formatters::Default)
      end

      it "should be writable" do
        formatter = Logging::Formatters::Colourful.new
        expect { subject.formatter = formatter }.not_to raise_error
      end
    end

    describe "logging methods" do
      it "should define #info" do
        expect { subject.info("Hello World!") }.not_to raise_error
      end

      it "should define #warn" do
        expect { subject.warn("Hello World!") }.not_to raise_error
      end

      it "should define #error" do
        expect { subject.error("Hello World!") }.not_to raise_error
      end
    end

    describe "#log" do
      it "should take log level and a single message"
      it "should take log level and multiple messages"
    end

    describe "#write" do
      before(:each) do
        subject.io = TestIO.new('test')
      end

      it "should write to the io object" do
        subject.io.write("Hello World!")
        subject.io.messages.last.should eql("Hello World!")
      end
    end
  end
end
