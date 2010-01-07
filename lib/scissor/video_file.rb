
module Scissor
  class VideoFile
    SUPPORTED_FORMATS = %w/avi flv/

    class Error < StandardError; end
    class UnknownFormat < Error; end

    def initialize(filename)
      @filename = Pathname.new(filename)
      @ext = @filename.extname.sub(/^\./, '').downcase

      unless SUPPORTED_FORMATS.include?(@ext)
        raise UnknownFormat
      end
    end

    def length
      Scissor.ffmpeg.get_duration(@filename)
    end
  end
end
