require 'mp3info'
require 'fileutils'

include FileUtils

class Scissor
  class Error < StandardError; end
  class CommandNotFound < Error; end
  class FileExists < Error; end
  class EmptyFragment < Error; end

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
    new_mp3 = self.class.new()
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

  def which(command)
    result = `which #{command}`
    $?.exitstatus == 0 ? result.chomp :
      (raise CommandNotFound.new(command + ' not found'))
  end

  def concat(other)
    other.fragments.each do |fragment|
      add_fragment(fragment)
    end

    self
  end

  alias :+ :concat

  def loop(count)
    orig_fragments = @fragments.clone

    (count - 1).times do
      orig_fragments.each do |fragment|
        add_fragment(fragment)
      end
    end

    self
  end

  alias :* :loop

  def split(count)
    splitted_duration = duration / count.to_f
    results = []

    count.times do |i|
      results << slice(i * splitted_duration, splitted_duration)
    end

    results
  end

  alias :/ :split

  def to_file(filename, options = {})
    if @fragments.empty?
      raise EmptyFragment
    end

    which('ffmpeg')
    which('mp3wrap')

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

    if outfiles.size == 1
      mv outfiles.first, filename
    else
      # concat mp3 files
      outfile = tmpdir + '/concat.mp3'
      cmd = "mp3wrap \"#{outfile}\" #{outfiles.join(' ')}"
      system cmd

      # fix duration and rename
      infile = tmpdir + '/concat_MP3WRAP.mp3'
      cmd = "ffmpeg -i \"#{infile}\" -acodec copy \"#{filename}\""
      system cmd
    end

    rm_rf tmpdir

    self.class.new(filename)
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
