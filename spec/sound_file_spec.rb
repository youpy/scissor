$:.unshift File.dirname(__FILE__)

require 'spec_helper'
require 'fileutils'

include FileUtils

describe Scissor::SoundFile do
  before do
    @mp3 = Scissor::SoundFile.new(fixture('sample.mp3'))
    @wav = Scissor::SoundFile.new(fixture('sine.wav'))
  end

  after do
  end

  it "raise error if unknown file format" do
    lambda {
      Scissor::SoundFile.new(fixture('foo.bar'))
    }.should raise_error(Scissor::SoundFile::UnknownFormat)
  end

  it "should get length" do
    @mp3.length.should be_close(178.1, 0.1)
    @wav.length.should eql(1.0)
  end
end
