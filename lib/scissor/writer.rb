require 'digest/md5'
require 'pathname'
require 'open4'
require 'temp_dir'

module Scissor
  class Writer
    include Loggable

    class Error < StandardError; end
    class FileExists < Error; end
    class EmptyFragment < Error; end
    class CommandFailed < Error; end

    def initialize
      @tracks = []
      @ecasound = Scissor::Ecasound.new
      @ffmpeg = Scissor::FFmpeg.new
    end

    def add_track(fragments)
      @tracks << fragments
    end

    def fragments_to_file(fragments, outfile, tmpdir)
      @ecasound.fragments_to_file fragments, outfile, tmpdir
    end

    def mix_files(filenames, outfile)
      @ecasound.mix_files filenames, outfile
    end

    def to_file(filename, options)
      filename = Pathname.new(filename)

      if @tracks.flatten.empty?
        raise EmptyFragment
      end

      options = {
        :overwrite => false,
        :bitrate => '128k'
      }.merge(options)

      if filename.exist?
        if options[:overwrite]
          filename.unlink
        else
          raise FileExists
        end
      end

      TempDir.create do |dir|
        tmpdir = Pathname.new(dir)
        tmpfiles = []

        @tracks.each_with_index do |fragments, track_index|
          tmpfiles << tmpfile = tmpdir + 'track_%s.wav' % track_index.to_s
          fragments_to_file(fragments, tmpfile, tmpdir)
        end

        mix_files(tmpfiles, final_tmpfile = tmpdir + 'tmp.wav')

        if filename.extname == '.wav'
          File.rename(final_tmpfile, filename)
        else
          @ffmpeg.convert final_tmpfile, filename, options
        end
      end
    end

  end
end
