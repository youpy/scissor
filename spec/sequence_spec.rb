$:.unshift File.dirname(__FILE__)

require 'spec_helper'

describe Scissor::Sequence do
  before do
    @foo = Scissor(fixture('sample.mp3'))
    @bar = Scissor(fixture('sine.wav'))
  end

  it "should instantiated" do
    seq = Scissor.sequence('ababaab', 1.5)
    seq.should be_an_instance_of(Scissor::Sequence)
  end

  it "should apply" do
    seq = Scissor.sequence('ababaab ab', 0.5)
    scissor = seq.apply(:a => @foo, :b => @bar)

    scissor.should be_an_instance_of(Scissor::Chunk)
    scissor.duration.should eql(5.0)
    scissor.fragments.size.should eql(10)

    scissor.fragments.each do |fragment|
      fragment.duration.should eql(0.5)
    end

    scissor.fragments[0].filename.to_s.should eql(fixture('sample.mp3'))
    scissor.fragments[1].filename.to_s.should eql(fixture('sine.wav'))
    scissor.fragments[2].filename.to_s.should eql(fixture('sample.mp3'))
    scissor.fragments[3].filename.to_s.should eql(fixture('sine.wav'))
    scissor.fragments[4].filename.to_s.should eql(fixture('sample.mp3'))
    scissor.fragments[5].filename.to_s.should eql(fixture('sample.mp3'))
    scissor.fragments[6].filename.to_s.should eql(fixture('sine.wav'))
    scissor.fragments[8].filename.to_s.should eql(fixture('sample.mp3'))
    scissor.fragments[9].filename.to_s.should eql(fixture('sine.wav'))
  end

  it "should append silence when applied instance does not have enough duration" do
    seq = Scissor.sequence('ba', 1.5)
    scissor = seq.apply(:a => @foo, :b => @bar)

    scissor.duration.should eql(3.0)
    scissor.fragments.size.should eql(3)
    scissor.fragments[0].filename.to_s.should eql(fixture('sine.wav'))
    scissor.fragments[1].filename.to_s.should match(/silence\.mp3/)
    scissor.fragments[2].filename.to_s.should eql(fixture('sample.mp3'))
  end
end
