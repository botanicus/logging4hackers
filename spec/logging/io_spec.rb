# encoding: utf-8

require 'spec_helper'

describe Logging::IO::Base do
  subject { described_class.new('logs.app.tests') }

  it "should have label" do
    subject.label.should eql('logs.app.tests')
  end
end

describe Logging::IO::Raw do
  # TODO: Capture STDOUT and test.
end

describe Logging::IO::Null do
  subject { described_class.new('logs.app.tests') }

  it "should provide #write" do
    expect {
      subject.write("Hello World!")
    }.not_to raise_error
  end
end

describe Logging::IO::File do
  # TODO
end

describe Logging::IO::Buffer do
  # TODO
end

describe Logging::IO::Pipe do
  # TODO
end

describe Logging::IO::AMQP do
  # TODO
end
