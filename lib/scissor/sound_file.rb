require 'mp3info'
require 'mp4info'
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

    class M4a < SoundFile
      def length
        info.SECS_NOROUND
      end

      # FIXME
      def mono?
        false
      end

      private

      def info
        @info ||= MP4Info.open(@filename.to_s)
      end
    end

    SUPPORTED_FORMATS = {
      :mp3 => Mp3,
      :wav => Wav,
      :m4a => M4a
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

class MP4Info
  private

  def parse_mvhd(io_stream, level, size)
    raise "Parse error" if size < 32
    data = read_or_raise(io_stream, size, "Premature end of file")

    version = data.unpack("C")[0] & 255
    if (version == 0)
      scale, duration = data[12..19].unpack("NN")
    elsif (version == 1)
      scale, hi, low = data[20..31].unpack("NNN")
      duration = hi * (2**32) + low
    else
      return
    end

    printf " %sDur/Scl=#{duration}/#{scale}\n", ' ' * ( 2 * level ) if $DEBUG

    secs = (duration * 1.0) / scale

    # add
    @info_atoms["SECS_NOROUND"] = secs

    @info_atoms["SECS"] = (secs).round
    @info_atoms["MM"] = (secs / 60).floor
    @info_atoms["SS"] = (secs - @info_atoms["MM"] * 60).floor
    @info_atoms["MS"] = (1000 * (secs - secs.floor)).round
    @info_atoms["TIME"] = sprintf "%02d:%02d", @info_atoms["MM"],
    @info_atoms["SECS"] - @info_atoms["MM"] * 60;
  end
end
