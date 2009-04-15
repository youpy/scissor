require 'digest/md5'
require 'pathname'
require 'open4'
require 'logger'
require 'bigdecimal'

module Scissor
  class Chunk
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO

    class << self
      attr_accessor :logger
    end

    class Error < StandardError; end
    class FileExists < Error; end
    class EmptyFragment < Error; end
    class OutOfDuration < Error; end
    class CommandFailed < Error; end

    attr_reader :fragments

    def initialize(filename = nil)
      @fragments = []

      if filename
        @fragments << Fragment.new(
          filename,
          0,
          SoundFile.new(filename).length)
      end
    end

    def add_fragment(fragment)
      @fragments << fragment
    end

    def add_fragments(fragments)
      fragments.each do |fragment|
        add_fragment(fragment)
      end
    end

    def duration
      BigDecimal(
        @fragments.inject(0) do |memo, fragment|
          memo += fragment.duration
        end.to_s).round(3).to_f
    end

    def slice(start, length)
      if start + length > duration
        raise OutOfDuration
      end

      new_instance = self.class.new
      remaining_start = start.to_f
      remaining_length = length.to_f

      @fragments.each do |fragment|
        new_fragment, remaining_start, remaining_length =
          fragment.create(remaining_start, remaining_length)

        if new_fragment
          new_instance.add_fragment(new_fragment)
        end

        if remaining_length == 0
          break
        end
      end

      new_instance
    end

    alias [] slice

    def concat(other)
      add_fragments(other.fragments)

      self
    end

    alias << concat

    def +(other)
      new_instance = Scissor()
      new_instance.add_fragments(@fragments + other.fragments)
      new_instance
    end

    def loop(count)
      orig_fragments = @fragments.clone

      (count - 1).times do
        add_fragments(orig_fragments)
      end

      self
    end

    alias * loop

    def split(count)
      splitted_duration = duration / count.to_f
      results = []

      count.times do |i|
        results << slice(i * splitted_duration, splitted_duration)
      end

      results
    end

    alias / split

    def fill(filled_duration)
      if @fragments.empty?
        raise EmptyFragment
      end

      remain = filled_duration
      new_instance = self.class.new

      while filled_duration > new_instance.duration
        if remain < duration
          added = slice(0, remain)
        else
          added = self
        end

        new_instance += added
        remain -= added.duration
      end

      new_instance
    end

    def replace(start, length, replaced)
      new_instance = self.class.new
      offset = start + length

      if offset > duration
        raise OutOfDuration
      end

      if start > 0
        new_instance += slice(0, start)
      end

      new_instance += replaced
      new_instance += slice(offset, duration - offset)

      new_instance
    end

    def reverse
      new_instance = self.class.new

      @fragments.reverse.each do |fragment|
        new_instance.add_fragment(Fragment.new(
            fragment.filename,
            fragment.start,
            fragment.duration,
            !fragment.reversed?))
      end

      new_instance
    end

    def to_file(filename, options = {})
      filename = Pathname.new(filename)

      if @fragments.empty?
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

      position = 0.0
      tmpdir = Pathname.new('/tmp/scissor-' + $$.to_s)
      tmpdir.mkpath
      tmpfile = tmpdir + 'tmp.wav'
      cmd = %w/ecasound/

      begin
        @fragments.each_with_index do |fragment, index|
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

        run_command(cmd.join(' '))

        if filename.extname == '.wav'
          File.rename(tmpfile, filename)
        else
          run_command("ffmpeg -i \"#{tmpfile}\" \"#{filename}\"")
        end
      ensure
        tmpdir.rmtree
      end

      self.class.new(filename)
    end

    alias > to_file

    def >>(filename)
      to_file(filename, :overwrite => true)
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

    def logger
      self.class.logger
    end
  end
end
