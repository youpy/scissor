require 'mp3info'
require 'pathname'
require 'riff/reader'

module Scissor
  class SoundFile
    SUPPORTED_FORMAT = %w/mp3 wav/

    class Error < StandardError; end
    class UnknownFormat < Error; end

    def initialize(filename)
      @filename = Pathname.new(filename)
      @ext = @filename.extname.sub(/^\./, '').downcase

      unless SUPPORTED_FORMAT.include?(@ext)
        raise UnknownFormat
      end
    end

    def length
      case @ext
      when 'mp3'
        Mp3Info.new(@filename).length
      when 'wav'
        riff = Riff::Reader.open(@filename ,"r")
        data = riff.root_chunk['data']
        fmt = riff.root_chunk['fmt ']

        data.length / fmt.body.unpack('s2i2')[3].to_f
      end
    end
  end
end
