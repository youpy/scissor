$:.unshift File.dirname(__FILE__)

require 'spec_helper'
require 'fileutils'

include FileUtils

describe Scissor::SoundFile do
  before do
    @mp3 = Scissor::SoundFile.new_from_filename(fixture('sample.mp3'))
    @wav = Scissor::SoundFile.new_from_filename(fixture('sine.wav'))
  end

  after do
  end

  it "raise error if unknown file format" do
    lambda {
      Scissor::SoundFile.new_from_filename(fixture('foo.bar'))
    }.should raise_error(Scissor::SoundFile::UnknownFormat)
  end

  it "should get length" do
    @mp3.length.should be_within(0.1).of(178.1)
    @wav.length.should eql(1.0)
  end

  describe '#mono?' do
    it "should return true if sound file is mono" do
      @mp3.should be_mono
      @wav.should_not be_mono

      Scissor::SoundFile.new_from_filename(fixture('mono.wav')).should be_mono
    end
  end
end
