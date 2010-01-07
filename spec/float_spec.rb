$:.unshift File.dirname(__FILE__)

require 'spec_helper'
require 'fileutils'
require 'tmpdir'

include FileUtils

describe Float do
  before do
    @sec = 27.027
  end

  after do
  end

  it "should get msec" do
    @sec.to_msec.should eql(27027)
  end

  it "should get ffmpeg time format" do
    @sec.to_ffmpegtime.should eql('00:00:27.027')

    h = 1
    m = 22
    sec = 33
    msec = 123
    val = h * 3600 + m * 60 + sec + msec/1000.0
    val.to_ffmpegtime.should eql('01:22:33.123')

    h = 10
    m = 2
    sec = 3
    msec = 3
    val = h * 3600 + m * 60 + sec + msec/1000.0
    val.to_ffmpegtime.should eql('10:02:03.003')
  end
end
