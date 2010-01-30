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

  it "should get video duration" do
    @video_file.length.should be_close(27, 0.1)
  end
end
