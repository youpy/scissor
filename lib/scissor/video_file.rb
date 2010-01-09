
module Scissor
  class VideoFile
    def initialize(filename)
      @filename = Pathname.new(filename)
      @ext = @filename.extname.sub(/^\./, '').downcase
    end

    def length
      Scissor.ffmpeg.get_duration(@filename)
    end
  end
end
