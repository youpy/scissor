require 'mp3info'
require 'digest/md5'
require 'pathname'
require 'riff/reader'

class Scissor
  class Error < StandardError; end
  class CommandNotFound < Error; end
  class CommandFailed < Error; end
  class FileExists < Error; end
  class EmptyFragment < Error; end
  class OutOfDuration < Error; end

  attr_reader :fragments

  def initialize(filename = nil)
    @fragments = []

    if filename
      @fragments << Fragment.new(
        Pathname.new(filename),
        0,
        SoundFile.new(filename).length)
    end
  end

  def add_fragment(fragment)
    @fragments << fragment
  end

  def duration
    @fragments.inject(0) do |memo, fragment|
      memo += fragment.duration
    end
  end

  def slice(start, length)
    if start + length > duration
      raise OutOfDuration
    end

    new_instance = self.class.new
    remain = length

    @fragments.each do |fragment|
      if start >= fragment.duration
        start -= fragment.duration

        next
      end

      if (start + remain) <= fragment.duration
        new_instance.add_fragment(Fragment.new(
            fragment.filename,
            fragment.start + start,
            remain,
            fragment.reversed?))

        break
      else
        remain = remain - (fragment.duration - start)
        new_instance.add_fragment(Fragment.new(
            fragment.filename,
            fragment.start + start,
            fragment.duration - start,
            fragment.reversed?))

        start = 0
      end
    end

    new_instance
  end

  def concat(other)
    other.fragments.each do |fragment|
      add_fragment(fragment)
    end

    self
  end

  alias + concat

  def loop(count)
    orig_fragments = @fragments.clone

    (count - 1).times do
      orig_fragments.each do |fragment|
        add_fragment(fragment)
      end
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

  def replace(start, duration, replaced)
    new_instance = self.class.new
    offset = start + duration

    if offset > self.duration
      raise OutOfDuration
    end

    if start > 0
      new_instance += slice(0, start)
    end

    new_instance += replaced
    new_instance += slice(offset, self.duration - offset)

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
    cmd = %w/ecasound -q/

    begin
      @fragments.each_with_index do |fragment, index|
        if !index.zero? && (index % 80).zero?
          run_command(cmd.join(' '))
          cmd = %w/ecasound -q/
        end

        fragment_tmpfile =
          tmpdir + (Digest::MD5.hexdigest(fragment.filename) + '.wav')

        unless fragment_tmpfile.exist?
          run_command("ffmpeg -i \"#{fragment.filename}\" \"#{fragment_tmpfile}\"")
        end

        cmd <<
          "-a:#{index} " +
          "-i:" +
          (fragment.reversed? ? 'reverse,' : '') +
          "select,#{fragment.start},#{fragment.duration},\"#{fragment_tmpfile}\" " +
          "-o:#{tmpfile} " +
          "-y:#{position}"

        position += fragment.duration
      end

      run_command(cmd.join(' '))
      run_command("ffmpeg -i \"#{tmpfile}\" \"#{filename}\"")
    ensure
      tmpdir.rmtree
    end

    self.class.new(filename)
  end

  alias > to_file

  def which(command)
    run_command("which #{command}")

    rescue CommandFailed
    raise CommandNotFound.new("#{command}: not found")
  end

  def run_command(cmd)
    unless system(cmd)
      raise CommandFailed.new(cmd)
    end
  end

  class << self
    def silence(duration)
      new(File.dirname(__FILE__) + '/../data/silence.mp3').
        slice(0, 1).
        fill(duration)
    end
  end

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

  class Fragment
    attr_reader :filename, :start, :duration

    def initialize(filename, start, duration, reverse = false)
      @filename = filename
      @start = start
      @duration = duration
      @reverse = reverse

      freeze
    end

    def reversed?
      @reverse
    end
  end
end
