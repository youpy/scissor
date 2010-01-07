$:.unshift File.dirname(__FILE__)

require 'spec_helper'
require 'fileutils'
require 'tmpdir'

include FileUtils

describe Scissor::VideoFile do
  before do
    @video_file = Scissor::VideoFile.new(fixture('sample.flv'))
  end

  after do
  end

  it "raise error if unknown file format" do
    lambda {
      Scissor::VideoFile.new(fixture('foo.bar'))
    }.should raise_error(Scissor::VideoFile::UnknownFormat)
  end

  it "should get video duration" do
    @video_file.length.should eql(27.027)
  end
end
