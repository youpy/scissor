# -*- coding: utf-8 -*-
module Scissor

  class FFmpeg < Command
    def initialize(command = which('ffmpeg'), work_dir = nil)
      super(:command => command,
            :work_dir => work_dir
            )
      which('ffmpeg')
    end

    def convert(infile, outfile, options={})
      params = ''
      if options[:bitrate]
        params += "-ab #{options[:bitrate]}"
        params += " "
      end
      run "#{params}-i #{infile} #{outfile}"
    end
  end
end
