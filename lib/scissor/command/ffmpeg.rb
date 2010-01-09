# -*- coding: utf-8 -*-
module Scissor

  class FFmpeg < Command
    class Error < StandardError; end
    class UnknownCodec < Error; end

    def initialize(command = which('ffmpeg'), work_dir = nil)
      super(:command => command,
            :work_dir => work_dir
            )
      which('ffmpeg')
    end

    def run_ffmpeg(*args)
      begin
        run *args
      rescue CommandFailed => e
        raise UnknownFormat if e.message =~ /Unable to find a suitable output format for/
        raise UnknownCodec if e.message =~ /Unknown encoder/
      end
    end

    def convert(infile, outfile, options={})
      params = ''
      if options[:bitrate]
        params += "-ab #{options[:bitrate]}"
        params += " "
      end
      run_ffmpeg "#{params}-i #{infile} #{outfile}"
    end

    def prepare(args)
      # flv2avi
      tmpfile = Pathname.new(args[:input_video])
      tmpfile = @work_dir + (tmpfile.basename.to_s.split('.')[0] + '.avi')
      unless tmpfile.exist?
        run_ffmpeg(["-i #{args[:input_video]}",
                    tmpfile
                   ].join(' '))
      end
      tmpfile
    end

    def cut(args)
      input_video = prepare args
      run_ffmpeg(["-i #{input_video}",
                  "-ss #{args[:start].to_f.to_ffmpegtime}",
                  "-t #{args[:duration].to_f.to_ffmpegtime}",
                  "#{args[:output_video]}"].join(' '))
      ScissorVideo(args[:output_video])
    end

    def encode(args)
      run_ffmpeg(["-i #{args[:input_video]}",
                  "-vcodec #{args[:vcodec] || 'msmpeg4v2'}",
                  "-acodec #{args[:acodec] || 'mp2'}",
                  "#{args[:output_video]}"].join(' '))
    end

    # sec
    def get_duration(video)
      result = run_ffmpeg("-i #{video}", true)
      duration = 0
      if result.match(/.*?Duration: (\d{2}):(\d{2}):(\d{2}).(\d{2}), start: .*?, bitrate: .*/m)
        duration = $1.to_i * 60 * 60 +
          $2.to_i * 60 +
          $3.to_i +
          ($4.to_i / 1000.0).to_f
      end
      duration
    end

    def strip_audio(video)
      tmpfile = Pathname.new(video)
      tmpfile = @work_dir + (tmpfile.basename.to_s.split('.')[0] + '.mp3')
      unless tmpfile.exist?
        run_ffmpeg([#"-y", # 同名ファイル上書き
                    "-i #{video}",
                    tmpfile].join(' '))
      end
      Scissor::Chunk.new(tmpfile)
    end
  end
end
