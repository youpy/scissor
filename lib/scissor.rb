require 'mp3info'
require 'fileutils'

include FileUtils

class Scissor
  class Error < StandardError; end
  class CommandNotFound < Error; end

  attr_reader :fragments

  def initialize(filename = nil)
    which('ffmpeg')
    which('mp3wrap')

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
    new_mp3 = self.class.new()
    remain = length

    @fragments.each do |fragment|
      if start >= fragment.duration
        start -= fragment.duration

        next
      end

      if (start + fragment.duration) >= remain
        new_mp3.add_fragment(Fragment.new(
            fragment.filename,
            fragment.start + start,
            remain))

        break
      else
        remain = remain - fragment.duration
        new_mp3.add_fragment(Fragment.new(
            fragment.filename,
            fragment.start + start,
            fragment.duration))

        start = 0
      end
    end

    new_mp3
  end

  def which(command)
    result = `which #{command}`
    $?.exitstatus == 0 ? result.chomp :
      (raise CommandNotFound.new(command + ' not found'))
  end

  def +(other)
    other.fragments.each do |fragment|
      add_fragment(fragment)
    end

    self
  end

  def *(count)
    orig_fragments = @fragments.clone

    (count - 1).times do
      orig_fragments.each do |fragment|
        add_fragment(fragment)
      end
    end

    self
  end

  def /(count)
    splitted_duration = duration / count.to_f
    results = []

    count.times do |i|
      results << slice(i, splitted_duration)
    end

    results
  end

  def to_file(filename)
    outfiles = []
    tmpdir = '/tmp/scissor-' + $$.to_s
    mkdir tmpdir

    # slice mp3 files
    @fragments.each_with_index do |fragment, index|
      outfile = tmpdir + '/' + index.to_s + '.mp3'
      outfiles << outfile
      cmd = "ffmpeg -i \"#{fragment.filename}\" -ss #{fragment.start} -t #{fragment.duration} #{outfile}"
      system cmd
    end

    # concat mp3 files
    cmd = "mp3wrap \"#{filename}\" #{outfiles.join(' ')}"
    system cmd

    # fix duration and rename
    cmd = "ffmpeg -i \"#{filename.sub(/\.mp3$/, '_MP3WRAP.mp3')}\" -acodec copy \"#{filename}\""
    system cmd

    rm_rf tmpdir

    open(filename)
  end

  class Fragment
    attr_reader :filename, :start, :duration

    def initialize(filename, start, duration)
      @filename = filename
      @start = start
      @duration = duration
    end
  end
end
