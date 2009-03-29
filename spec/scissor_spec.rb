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

  it "should write to file and return new instance of Scissor" do
    new_mp3 = @mp3.slice(0, 120) + @mp3.slice(150, 20)
    result = new_mp3.to_file('/tmp/scissor-test/out.mp3')
    result.should be_an_instance_of(Scissor)
    result.duration.to_i.should eql(140)
  end

  it "should overwrite existing file" do
    result = @mp3.slice(0, 10).to_file('/tmp/scissor-test/out.mp3')
    result.duration.to_i.should eql(10)

    result = @mp3.slice(0, 12).to_file('/tmp/scissor-test/out.mp3',
      :overwrite => true)
    result.duration.to_i.should eql(12)
  end

  it "should raise error if overwrite option is false" do
    result = @mp3.slice(0, 10).to_file('/tmp/scissor-test/out.mp3')
    result.duration.to_i.should eql(10)

    lambda {
      @mp3.slice(0, 10).to_file('/tmp/scissor-test/out.mp3',
        :overwrite => false)
    }.should raise_error(Scissor::FileExists)

    lambda {
      @mp3.slice(0, 10).to_file('/tmp/scissor-test/out.mp3')
    }.should raise_error(Scissor::FileExists)
  end

  it "should raise error if no fragment are given" do
    lambda {
      Scissor.new.to_file('/tmp/scissor-test/out.mp3')
    }.should raise_error(Scissor::EmptyFragment)
  end
end
