$:.unshift File.dirname(__FILE__)

require 'spec_helper'
require 'fileutils'
require 'fakeweb'

include FileUtils

describe Scissor do
  before do
    @mp3 = Scissor(fixture('sample.mp3'))
    mkdir '/tmp/scissor-test'

    FakeWeb.clean_registry
  end

  after do
    rm_rf '/tmp/scissor-test'
  end

  it "should set default logger level to Logger::WARN" do
    [Scissor, FFMPEG].each do |mod|
      mod.logger.level.should eql(Logger::WARN)
    end
  end

  it "should create from url" do
    url = 'http://example.com/sample_mp3'
    FakeWeb.register_uri(:get, url, :body => fixture('sample.mp3'), :content_type => 'audio/mpeg')

    mp3 = Scissor(url)

    mp3.should be_an_instance_of(Scissor::Tape)
    mp3.duration.should be_within(0.1).of(178.1)
  end

  it "should expand given path" do
    cp fixture('sample.mp3'), '/tmp/scissor-test'

    mp3 = Scissor('~/../../../../../../../../../../tmp/scissor-test/sample.mp3')
    mp3.should be_an_instance_of(Scissor::Tape)
    mp3.duration.should be_within(0.1).of(178.1)
  end

  it "should get duration" do
    @mp3.should respond_to(:duration)
    @mp3.duration.should be_within(0.1).of(178.1)
  end

  it "should slice" do
    @mp3.should respond_to(:slice)
    @mp3.slice(0, 120).duration.should eql(120.0)
    @mp3.slice(150, 20).duration.should eql(20.0)
  end

  it "should slice like array" do
    @mp3[0, 120].duration.should eql(120.0)
    @mp3[150, 20].duration.should eql(20.0)
  end

  it "should cut down if sliced range is out of duration" do
    @mp3.slice(0, 179).duration.should be_within(0.1).of(178.1)
  end

  it "should concatenate" do
    a = @mp3.slice(0, 120)
    scissor = a.concat(@mp3.slice(150, 20))
    scissor.duration.should eql(140.0)
    a.duration.should eql(140.0)
  end

  it "should concatenate using double 'less than' operator" do
    a = @mp3.slice(0, 120)
    scissor = a << @mp3.slice(150, 20)
    scissor.duration.should eql(140.0)
    a.duration.should eql(140.0)
  end

  it "should concat silence" do
    scissor = @mp3.slice(0, 12).concat(Scissor.silence(0.32009))
    scissor.duration.should be_within(0.01).of(12.32)
  end

  it "should concatenate and create new instance" do
    a = @mp3.slice(0, 120)
    scissor = a + @mp3.slice(150, 20)
    scissor.duration.should eql(140.0)
    a.duration.should eql(120.0)
  end

  it "should slice concatenated one" do
    scissor = @mp3.slice(0.33, 1).concat(@mp3.slice(0.2, 0.1)).slice(0.9, 0.2)

    scissor.duration.should be_within(0.001).of(0.2)
    scissor.fragments.size.should eql(2)
    scissor.fragments[0].start.should be_within(0.001).of(1.23)
    scissor.fragments[0].duration.should be_within(0.001).of(0.1)
    scissor.fragments[1].start.should be_within(0.001).of(0.2)
    scissor.fragments[1].duration.should be_within(0.001).of(0.1)
  end

  it "should loop" do
    scissor = @mp3.slice(0, 10)
    scissor.loop(3).duration.should eql(30.0)
    scissor.duration.should eql(10.0)
  end

  it "should loop using arithmetic operator" do
    scissor = @mp3.slice(0, 10) * 3
    scissor.duration.should eql(30.0)
  end

  it "should split" do
    splits = (@mp3.slice(0.33, 1) + @mp3.slice(0.2, 0.1)).split(5)
    splits.length.should eql(5)
    splits.each do |split|
      split.duration.should be_within(0.001).of(0.22)
    end

    splits[0].fragments.size.should eql(1)
    splits[1].fragments.size.should eql(1)
    splits[2].fragments.size.should eql(1)
    splits[3].fragments.size.should eql(1)
    splits[4].fragments.size.should eql(2)
  end

  it "should split using arithmetic operator" do
    splits = (@mp3.slice(0.33, 1) + @mp3.slice(0.2, 0.1)) / 5
    splits.length.should eql(5)
    splits.each do |split|
      split.duration.should be_within(0.001).of(0.22)
    end

    splits[0].fragments.size.should eql(1)
    splits[1].fragments.size.should eql(1)
    splits[2].fragments.size.should eql(1)
    splits[3].fragments.size.should eql(1)
    splits[4].fragments.size.should eql(2)
  end

  it "should fill" do
    scissor = (@mp3.slice(0, 6) + @mp3.slice(0, 2)).fill(15)
    scissor.duration.should eql(15.0)
    scissor.fragments.size.should eql(4)
    scissor.fragments[0].duration.should eql(6.0)
    scissor.fragments[1].duration.should eql(2.0)
    scissor.fragments[2].duration.should eql(6.0)
    scissor.fragments[3].duration.should eql(1.0)
  end

  it "should replace" do
    scissor = @mp3.slice(0, 100).replace(60, 30, @mp3.slice(0, 60))
    scissor.duration.should eql(130.0)
    scissor.fragments.size.should eql(3)
    scissor.fragments[0].start.should eql(0.0)
    scissor.fragments[0].duration.should eql(60.0)
    scissor.fragments[1].start.should eql(0.0)
    scissor.fragments[1].duration.should eql(60.0)
    scissor.fragments[2].start.should eql(90.0)
    scissor.fragments[2].duration.should eql(10.0)
  end

  it "should reverse" do
    scissor = (@mp3.slice(0, 10) + @mp3.slice(0, 5)).reverse
    scissor.duration.should eql(15.0)
    scissor.fragments.size.should eql(2)
    scissor.fragments[0].start.should eql(0.0)
    scissor.fragments[0].duration.should eql(5.0)
    scissor.fragments[0].should be_reversed
    scissor.fragments[1].start.should eql(0.0)
    scissor.fragments[1].duration.should eql(10.0)
    scissor.fragments[0].should be_reversed
  end

  it "should re-reverse" do
    scissor = (@mp3.slice(0, 10) + @mp3.slice(0, 5)).reverse.reverse
    scissor.duration.should eql(15.0)
    scissor.fragments.size.should eql(2)
    scissor.fragments[0].start.should eql(0.0)
    scissor.fragments[0].duration.should eql(10.0)
    scissor.fragments[0].should_not be_reversed
    scissor.fragments[1].start.should eql(0.0)
    scissor.fragments[1].duration.should eql(5.0)
    scissor.fragments[0].should_not be_reversed
  end

  it "should change pitch" do
    scissor = @mp3.slice(0, 10) + @mp3.slice(0, 5)

    scissor.duration.should eql(15.0)
    scissor.pitch(50).duration.should eql(30.0)
    scissor.pitch(50).pitch(50).fragments[0].pitch.should eql(25.0)
    scissor.pitch(50).pitch(50).duration.should eql(60.0)
  end

  it "should stretch" do
    scissor = @mp3.slice(0, 0.1)

    scissor.duration.should eql(0.1)
    scissor.pitch((0.1 / 120) * 100, true).duration.should be_within(0.01).of(120.0)
    scissor.stretch((120 / 0.1) * 100).duration.should be_within(0.1).of(120.0)

    stretched = scissor.stretch((120 / 0.1) * 100).slice(0, 10)
    stretched.fragments.first.should be_stretched

    stretched1 = scissor.stretch((120 / 0.1) * 100)
    stretched2 = scissor.stretch((120 / 0.1) * 100)
    stretched = (stretched1 + stretched2).slice(100, 50)
    stretched.fragments.first.should be_stretched

    scissor = (@mp3.slice(0, 10) + @mp3.slice(0, 5)).stretch(200).reverse
    scissor.fragments.first.should be_stretched
  end

  it "should pan" do
    scissor = @mp3.slice(0, 10) + @mp3.slice(0, 5)

    scissor.pan(10).fragments[0].pan.should eql(10)
    scissor.pan(10).pan(10).fragments[0].pan.should eql(10)
  end

  it "should join instances of scissor" do
    a = @mp3.slice(0, 120)
    b = @mp3.slice(150, 20)

    scissor = Scissor.join([a, b])
    scissor.duration.should eql(140.0)
    scissor.fragments[0].duration.should eql(120.0)
  end

  it "should mix instances of scissor" do
    a = @mp3.slice(0, 120)
    b = @mp3.slice(150, 20)

    scissor = Scissor.mix([a, b], '/tmp/scissor-test/out.mp3')
    scissor.should be_an_instance_of(Scissor::Tape)
    scissor.duration.should be_within(0.1).of(120)
    scissor.fragments.size.should eql(1)
  end

  it "should expand if replaced range is out of duration" do
    replaced = @mp3.slice(0, 100).replace(60, 41, @mp3.slice(0, 60))
    replaced.duration.should eql(120.0)
  end

  it "should write to file and return new instance of Scissor" do
    scissor = @mp3.slice(0, 120) + @mp3.slice(150, 20)
    result = scissor.to_file('/tmp/scissor-test/out.mp3')
    result.should be_an_instance_of(Scissor::Tape)
    result.duration.should be_within(0.1).of(140)
  end

  it "should write to mp3 file" do
    scissor = @mp3.slice(0, 120) + @mp3.slice(150, 20)
    result = scissor.to_file('/tmp/scissor-test/out.mp3')
    result.duration.should be_within(0.1).of(140)
  end

  it "should write to expanded path" do
    @mp3.to_file('~/../../../../../../../../../../tmp/scissor-test/sample.mp3')

    mp3 = Scissor('/tmp/scissor-test/sample.mp3')
    mp3.should be_an_instance_of(Scissor::Tape)
  end

  it "should write to wav file" do
    scissor = @mp3.slice(0, 120) + @mp3.slice(150, 20)
    result = scissor.to_file('/tmp/scissor-test/out.wav')
    result.duration.should be_within(0.1).of(140)
  end

  it "should write to m4a file" do
    scissor = @mp3.slice(0, 120) + @mp3.slice(150, 20)
    result = scissor.to_file('/tmp/scissor-test/out.m4a')
    result.duration.should be_within(0.1).of(140)
  end

  it "should write to file using 'greater than' operator" do
    result = @mp3.slice(0, 120) + @mp3.slice(150, 20) > '/tmp/scissor-test/out.wav'
    result.duration.should be_within(0.1).of(140)
  end

  it "should write to file with many fragments" do
    scissor = (@mp3.slice(0, 120) / 100).inject(Scissor()){|m, s| m + s } + @mp3.slice(10, 20)
    result = scissor.to_file('/tmp/scissor-test/out.mp3')
    result.should be_an_instance_of(Scissor::Tape)
    result.duration.should be_within(0.1).of(140)
  end

  it "should overwrite existing file" do
    result = @mp3.slice(0, 10).to_file('/tmp/scissor-test/out.mp3')
    result.duration.should be_within(0.1).of(10)

    result = @mp3.slice(0, 12).to_file('/tmp/scissor-test/out.mp3',
      :overwrite => true)
    result.duration.should be_within(0.1).of(12)
  end

  it "should overwrite existing file using double 'greater than' oprator" do
    result = @mp3.slice(0, 10).to_file('/tmp/scissor-test/out.mp3')
    result.duration.should be_within(0.1).of(10)

    result = @mp3.slice(0, 12) >> '/tmp/scissor-test/out.mp3'
    result.duration.should be_within(0.1).of(12)
  end

  it "should write to file in the variable pitch" do
    scissor = @mp3.slice(0, 120) + @mp3.slice(150, 20)

    result = scissor.pitch(50).to_file('/tmp/scissor-test/out.mp3')
    result.duration.should be_within(0.1).of(280)

    result = scissor.pitch(200).to_file('/tmp/scissor-test/out.mp3', :overwrite => true)
    result.duration.should be_within(0.1).of(70)
  end

  it "should raise error if overwrite option is false" do
    result = @mp3.slice(0, 10).to_file('/tmp/scissor-test/out.mp3')
    result.duration.should be_within(0.1).of(10)

    lambda {
      @mp3.slice(0, 10).to_file('/tmp/scissor-test/out.mp3',
        :overwrite => false)
    }.should raise_error(Scissor::Writer::FileExists)

    lambda {
      @mp3.slice(0, 10).to_file('/tmp/scissor-test/out.mp3')
    }.should raise_error(Scissor::Writer::FileExists)
  end

  it "should raise error if no fragment are given" do
    lambda {
      Scissor().to_file('/tmp/scissor-test/out.mp3')
    }.should raise_error(Scissor::Writer::EmptyFragment)
  end

  it "should silence" do
    scissor = @mp3.slice(0, 1.0)

    Scissor.should_receive(:silence).with(1.0)

    scissor.silence
  end
end
