require 'scissor/loggable'
require 'scissor/tape'
require 'scissor/fragment'
require 'scissor/sound_file'
require 'scissor/sequence'
require 'scissor/writer'

def Scissor(filename_or_url = nil)
  if filename_or_url && filename_or_url =~ /^http/
    Scissor::Tape.new_from_url(filename_or_url)
  else
    Scissor::Tape.new(filename_or_url)
  end
end

require 'logger'

module Scissor
  @logger = Logger.new(STDOUT)
  @logger.level = Logger::INFO

  class << self
    attr_accessor :logger
  end

  def logger
    self.class.logger
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

# for ruby 1.9
if IO.instance_methods.include? :getbyte
  class << Riff::Reader::Chunk
    alias :read_bytes_to_int_original :read_bytes_to_int
    def read_bytes_to_int file, bytes
      require 'delegate'
      file_delegate = SimpleDelegator.new(file)
      def file_delegate.getc
        getbyte
      end
      read_bytes_to_int_original file_delegate, bytes
    end
  end
end

