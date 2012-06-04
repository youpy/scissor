require 'mp3info'
require 'pathname'
require 'riff/reader'

module Scissor
  class SoundFile
    class Mp3 < SoundFile
      def length
        info.length
      end

      def mono?
        info.channel_mode == 'Single Channel'
      end

      private

      def info
        @info ||= Mp3Info.new(@filename.to_s)
      end
    end

    class Wav < SoundFile
      def length
        data.length / fmt.body.unpack('s2i2')[3].to_f
      end

      def mono?
        fmt.body.unpack('s2')[1] == 1
      end

      private

      def riff
        @riff ||= Riff::Reader.open(@filename ,"r")
      end

      def data
        @data ||= riff.root_chunk['data']
      end

      def fmt
        @fmt ||= riff.root_chunk['fmt ']
      end
    end

    SUPPORTED_FORMATS = {
      :mp3 => Mp3,
      :wav => Wav
    }

    class Error < StandardError; end
    class UnknownFormat < Error; end

    def self.new_from_filename(filename)
      ext = filename.extname.sub(/^\./, '').downcase

      unless klass = SUPPORTED_FORMATS[ext.to_sym]
        raise UnknownFormat
      end

      klass.new(filename)
    end

    def initialize(filename)
      @filename = Pathname.new(filename)
    end
  end
end
