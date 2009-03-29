$:.unshift File.dirname(__FILE__)

require 'spec_helper'
require 'fileutils'

include FileUtils

describe Scissor do
  before do
    @mp3 = Scissor.new(fixture('sample.mp3'))
    mkdir '/tmp/scissor-test'
  end

  after do
    rm_rf '/tmp/scissor-test'
  end

  it "should get duration" do
    @mp3.should respond_to(:duration)
    @mp3.duration.should eql(178.183)
  end

  it "should slice" do
    @mp3.should respond_to(:slice)
    @mp3.slice(0, 120).duration.should eql(120)
    @mp3.slice(150, 20).duration.should eql(20)
  end

  it "should paste" do
    new_mp3 = @mp3.slice(0, 120) + @mp3.slice(150, 20)
    new_mp3.duration.should eql(140)
  end

  it "should loop" do
    new_mp3 = @mp3.slice(0, 10) * 3
    new_mp3.duration.should eql(30)
  end

  it "should split" do
    splits = @mp3.slice(0, 10) / 10
    splits.length.should eql(10)
    splits.each do |split|
      split.duration.to_i.should eql(1)
    end
  end

  it "should write to file" do
    new_mp3 = @mp3.slice(0, 120) + @mp3.slice(150, 20)
    file = new_mp3.to_file('/tmp/scissor-test/out.mp3')
    file.should be_an_instance_of(File)
    File.exist?(file).should be_true
    Scissor.new(file.path).duration.to_i.should eql(140)
  end
end
