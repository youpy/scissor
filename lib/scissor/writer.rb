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
    end

    def add_fragments(fragments)
      @tracks << fragments
    end

    def to_file(filename, options)
      filename = Pathname.new(filename)

      if @tracks.flatten.empty?
        raise EmptyFragment
      end

      which('ecasound')
      which('ffmpeg')

      options = {
        :overwrite => false
      }.merge(options)

      filename = Pathname.new(filename)

      if filename.exist?
        if options[:overwrite]
          filename.unlink
        else
          raise FileExists
        end
      end

      TempDir.create do |dir|
        tmpdir = Pathname.new(dir)
        tmpfile = tmpdir + 'tmp.wav'
        cmd = %w/ecasound/

        @tracks.each do |fragments|
          position = 0.0

          fragments.each_with_index do |fragment, index|
            fragment_filename = fragment.filename
            fragment_duration = fragment.duration

            if !index.zero? && (index % 80).zero?
              run_command(cmd.join(' '))
              cmd = %w/ecasound/
            end

            fragment_tmpfile =
              fragment_filename.extname.downcase == '.wav' ? fragment_filename :
              tmpdir + (Digest::MD5.hexdigest(fragment_filename) + '.wav')

            unless fragment_tmpfile.exist?
              run_command("ffmpeg -i \"#{fragment_filename}\" \"#{fragment_tmpfile}\"")
            end

            cmd <<
              "-a:#{index} " +
              "-i:" +
              (fragment.reversed? ? 'reverse,' : '') +
              "select,#{fragment.start},#{fragment_duration},\"#{fragment_tmpfile}\" " +
              "-o:#{tmpfile} " +
              "-y:#{position}"

            position += fragment_duration
          end
        end

        run_command(cmd.join(' '))

        if filename.extname == '.wav'
          File.rename(tmpfile, filename)
        else
          run_command("ffmpeg -i \"#{tmpfile}\" \"#{filename}\"")
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
