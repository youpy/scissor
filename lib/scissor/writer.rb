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

      which('ecasound')
      which('ffmpeg')
    end

    def add_track(fragments)
      @tracks << fragments
    end

    def fragments_to_file(fragments, outfile, tmpdir)
      position = 0.0
      cmd = %w/ecasound/

      fragments.each_with_index do |fragment, index|
        fragment_filename = fragment.filename
        fragment_duration = fragment.duration

        if !index.zero? && (index % 80).zero?
          run_command(cmd.join(' '))
          cmd = %w/ecasound/
        end

        fragment_outfile =
          fragment_filename.extname.downcase == '.wav' ? fragment_filename :
          tmpdir + (Digest::MD5.hexdigest(fragment_filename) + '.wav')

        unless fragment_outfile.exist?
          run_command("ffmpeg -i \"#{fragment_filename}\" \"#{fragment_outfile}\"")
        end

        cmd <<
          "-a:#{index} " +
          "-i:" +
          (fragment.reversed? ? 'reverse,' : '') +
          "select,#{fragment.start},#{fragment.true_duration},\"#{fragment_outfile}\" " +
          "-o:#{outfile} " +
          (fragment.pitch.to_f == 100.0 ? "" : "-ei:#{fragment.pitch} ") +
          "-y:#{position}"

        position += fragment_duration
      end

      run_command(cmd.join(' '))
    end

    def mix_files(filenames, outfile)
      cmd = %w/ecasound/

      filenames.each_with_index do |tf, index|
        cmd << "-a:#{index} -i:#{tf}"
      end

      cmd << "-a:all -o:#{outfile}"
      run_command(cmd.join(' '))
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
          run_command("ffmpeg -ab #{options[:bitrate]} -i \"#{final_tmpfile}\" \"#{filename}\"")
        end
      end
    end

    def which(command)
      run_command("which #{command}")
    end

    def run_command(cmd)
      logger.debug("run_command: #{cmd}")

      result = ''
      status = Open4.popen4(cmd) do |pid, stdin, stdout, stderr|
        logger.debug(stderr.read)
        result = stdout.read
      end

      if status.exitstatus != 0
        raise CommandFailed.new(cmd)
      end

      return result
    end
  end
end
