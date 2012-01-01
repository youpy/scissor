$:.unshift File.dirname(__FILE__)

require 'spec_helper'

describe Scissor::Fragment do
  before do
    @fragment = Scissor::Fragment.new(fixture('sample.mp3'), 5.5, 12.4)
  end

  it "should have a filename as an instance of Pathname" do
    @fragment.filename.should be_an_instance_of(Pathname)
    @fragment.filename.should eql(fixture('sample.mp3'))
  end

  it "should have a filename with absolute path" do
    @fragment.filename.should be_absolute
  end

  it "should have a start point" do
    @fragment.start.should eql(5.5)
  end

  it "should have a duration" do
    @fragment.duration.should eql(12.4)
  end

  it "should freezed" do
    lambda {
      @fragment.instance_eval { @duration = 1 }
    }.should raise_error
  end

  it "should have a pitch" do
    fragment = Scissor::Fragment.new(fixture('sample.mp3'), 5, 10.5, false, 50)

    fragment.pitch.should eql(50)
    fragment.duration.should eql(21.0)
  end

  it "should return new fragment and remaining start point and length" do
    new_fragment, remaining_start, remaining_length = @fragment.create(0.5, 1.0)
    new_fragment.filename.should eql(fixture('sample.mp3'))
    new_fragment.start.should eql(6.0)
    new_fragment.duration.should eql(1.0)
    remaining_start.should eql(0)
    remaining_length.should eql(0)

    new_fragment, remaining_start, remaining_length = @fragment.create(12.9, 1.0)
    new_fragment.should be_nil
    remaining_start.should eql(0.5)
    remaining_length.should eql(1.0)

    new_fragment, remaining_start, remaining_length = @fragment.create(11.9, 1.0)
    new_fragment.filename.should eql(fixture('sample.mp3'))
    new_fragment.start.should eql(17.4)
    new_fragment.duration.should eql(0.5)
    remaining_start.should eql(0)
    remaining_length.should eql(0.5)
  end

  it "should return new fragment and remaining start point and length in half pitch" do
    fragment = Scissor::Fragment.new(fixture('sample.mp3'), 5, 10.5, false, 50)

    new_fragment, remaining_start, remaining_length = fragment.create(0.5, 1.0)
    new_fragment.filename.should eql(fixture('sample.mp3'))
    new_fragment.start.should eql(5.25)
    new_fragment.duration.should eql(1.0)
    new_fragment.pitch.should eql(50)
    remaining_start.should eql(0)
    remaining_length.should eql(0)

    new_fragment, remaining_start, remaining_length = fragment.create(10.5, 1.0)
    new_fragment.filename.should eql(fixture('sample.mp3'))
    new_fragment.start.should eql(10.25)
    new_fragment.duration.should eql(1.0)
    new_fragment.pitch.should eql(50)
    remaining_start.should eql(0)
    remaining_length.should eql(0)

    new_fragment, remaining_start, remaining_length = fragment.create(20, 3)
    new_fragment.start.should eql(15.0)
    new_fragment.duration.should eql(1.0)
    new_fragment.pitch.should eql(50)
    remaining_start.should eql(0)
    remaining_length.should eql(2.0)

    new_fragment, remaining_start, remaining_length = fragment.create(21, 1.0)
    new_fragment.should be_nil
    remaining_start.should eql(0.0)
    remaining_length.should eql(1.0)

    new_fragment, remaining_start, remaining_length = fragment.create(22, 1.0)
    new_fragment.should be_nil
    remaining_start.should eql(1.0)
    remaining_length.should eql(1.0)
  end
end
