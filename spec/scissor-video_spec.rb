$:.unshift File.dirname(__FILE__)

require 'spec_helper'
require 'fileutils'
require 'tmpdir'

include FileUtils

describe Scissor do
  before do
    @video = ScissorVideo(fixture('sample.flv'))
    @tmp_dir = "#{Dir.tmpdir}/scissor-video-test"
    mkdir @tmp_dir
  end

  after do
    rm_rf @tmp_dir
  end

  it "should get video duration" do
    @video.should respond_to(:duration)
    @video.duration.should be_close(27, 0.1)
  end

  it "should slice" do
    @video.should respond_to(:slice)
    @video.slice(0, 20).duration.should eql(20.0)
    @video.slice(20, 5).duration.should eql(5.0)
  end

  it "should write to file and return new instance of Scissor" do
    scissor = @video.slice(0, 20) + @video.slice(20, 5)
    result = scissor.to_file(@tmp_dir + '/out.avi', :save_work_dir => true)
    result.should be_an_instance_of(Scissor::VideoChunk)
    result.duration.to_i.should eql(25)

    ffmpeg = Scissor::FFmpeg.new('ffmpeg', nil, true)
    ffmpeg.cleanup
  end

  it "should write to file with many fragments" do
    scissor = (@video.slice(0, 20) / 10).inject(ScissorVideo()){|m, s| m + s } + @video.slice(20, 5)
    result = scissor.to_file(@tmp_dir + '/out.avi', :save_work_dir => true)
    result.should be_an_instance_of(Scissor::VideoChunk)
    result.duration.to_i.should eql(25)

    ffmpeg = Scissor::FFmpeg.new('ffmpeg', nil, true)
    ffmpeg.cleanup
  end

  def test_work_dir(video, tmp_dir)
    scissor = video.slice(0, 20) + video.slice(0, 5)
    result = scissor.to_file("#{tmp_dir}/out.avi", :save_work_dir => true)
    result.should be_an_instance_of(Scissor::VideoChunk)
    result.duration.to_i.should eql(25)

    ffmpeg = Scissor::FFmpeg.new('ffmpeg', nil, true)
    ffmpeg.work_dir.should be_exist
    ffmpeg.cleanup
  end

  it "should save workfiles if save_work_dir option is true" do
    test_work_dir(@video, @tmp_dir)
  end

  it "should work with workspace if workspace was specified" do
    Scissor.workspace = './workspace01'

    video = ScissorVideo(fixture('sample.flv'))
    test_work_dir(video, Scissor.workspace)

    Scissor.workspace = nil
  end
end
