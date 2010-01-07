require 'scissor/loggable'
require 'scissor/chunk'
require 'scissor/fragment'
require 'scissor/sound_file'
require 'scissor/sequence'
require 'scissor/writer'

require 'scissor/command'
%w[ecasound ffmpeg].each do |c|
  require "scissor/command/#{c}"
end

def Scissor(*args)
  Scissor::Chunk.new(*args)
end

require 'logger'

module Scissor
  @logger = Logger.new(STDOUT)
  @logger.level = Logger::INFO

  class << self
    attr_accessor :logger, :workspace
  end

  def logger
    self.class.logger
  end

  def workspace
    self.class.workspace
  end

  class << self
    def silence(duration)
      Scissor(File.dirname(__FILE__) + '/../data/silence.mp3').
        slice(0, 1).
        fill(duration)
    end

    def sequence(*args)
      Scissor::Sequence.new(*args)
    end

    def join(scissor_array)
      scissor_array.inject(Scissor()) do |m, scissor|
        m + scissor
      end
    end

    def mix(scissor_array, filename, options = {})
      writer = Scissor::Writer.new

      scissor_array.each do |scissor|
        writer.add_track(scissor.fragments)
      end

      writer.to_file(filename, options)

      Scissor(filename)
    end
  end
end
