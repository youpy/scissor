require 'scissor/loggable'
require 'scissor/chunk'
require 'scissor/fragment'
require 'scissor/sound_file'
require 'scissor/sequence'
require 'scissor/writer'

require 'scissor/command'
%w[ecasound ffmpeg mencoder].each do |c|
  require "scissor/command/#{c}"
end

require 'scissor/video_chunk'
require 'scissor/video_file'
require 'scissor/float'

# TODO: cleaning
def ScissorVideo(*args)
  Scissor::VideoChunk.new(*args)
end

#def Scissor(*args)
#  Scissor::Chunk.new(*args)
#end
def Scissor(*args)
#  Scissor::Chunk.new(*args)
  if args.length == 0
    Scissor::Chunk.new(*args)
  else
    filename = args[0]
    f = Pathname.new(filename)
    ext = f.extname.sub(/^\./, '').downcase
    if Scissor::SoundFile::SUPPORTED_FORMATS.include?(ext)
      Scissor::Chunk.new(filename)
    else
      ScissorVideo(filename)
    end
  end
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


  # TODO: cleaning
  class << self
    def ffmpeg(*args)
      FFmpeg.new(*args)
    end

    def mencoder(*args)
      Mencoder.new(*args)
    end
  end
end
