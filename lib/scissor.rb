require 'mp3info'
require 'fileutils'

include FileUtils

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
        filename,
        0,
        Mp3Info.new(filename).length)
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

    new_mp3 = self.class.new
    remain = length

    @fragments.each do |fragment|
      if start >= fragment.duration
        start -= fragment.duration

        next
      end

      if (start + remain) <= fragment.duration
        new_mp3.add_fragment(Fragment.new(
            fragment.filename,
            fragment.start + start,
            remain))

        break
      else
        remain = remain - (fragment.duration - start)
        new_mp3.add_fragment(Fragment.new(
            fragment.filename,
            fragment.start + start,
            fragment.duration - start))

        start = 0
      end
    end

    new_mp3
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
    new_mp3 = self.class.new

    while filled_duration > new_mp3.duration
      if remain < duration
        added = slice(0, remain)
      else
        added = self
      end

      new_mp3 += added
      remain -= added.duration
    end

    new_mp3
  end

  def replace(start, duration, replaced)
    new_mp3 = self.class.new
    offset = start + duration

    if offset > self.duration
      raise OutOfDuration
    end

    if start > 0
      new_mp3 += slice(0, start)
    end

    new_mp3 += replaced
    new_mp3 += slice(offset, self.duration - offset)

    new_mp3
  end

  def to_file(filename, options = {})
    if @fragments.empty?
      raise EmptyFragment
    end

    which('ecasound')
    which('ffmpeg')
    which('mpg123')

    options = {
      :overwrite => false
    }.merge(options)

    if File.exists?(filename)
      if options[:overwrite]
        File.unlink(filename)
      else
        raise FileExists
      end
    end

    position = 0.0
    tmpfile = '/tmp/scissor-' + $$.to_s + '.wav'
    cmd = %w/ecasound/

    begin
      @fragments.each_with_index do |fragment, index|
        if !index.zero? && (index % 80).zero?
          run_command(cmd.join(' '))
          cmd = %w/ecasound/
        end

        cmd << "-a:#{index} -i \"#{fragment.filename}\" -y:#{fragment.start} -t:#{fragment.duration} -o #{tmpfile} -y:#{position}"
        position += fragment.duration
      end

      run_command(cmd.join(' '))

      cmd = "ffmpeg -i \"#{tmpfile}\" \"#{filename}\""
      run_command(cmd)
    ensure
      rm tmpfile
    end

    self.class.new(filename)
  end

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

  class Fragment
    attr_reader :filename, :start, :duration

    def initialize(filename, start, duration)
      @filename = filename
      @start = start
      @duration = duration

      freeze
    end
  end
end
