$:.unshift File.dirname(__FILE__)

require 'spec_helper'
require 'fileutils'

include FileUtils

describe Scissor::Chunk do
  before do
  end

  describe "#to_videochunk" do
    it "should return Scissor::VideoChunk instance." do
      Scissor::Chunk.new(fixture('sample.mp3')).to_videochunk(fixture('sample.flv')).should be_instance_of(Scissor::VideoChunk)
    end
  end
end
