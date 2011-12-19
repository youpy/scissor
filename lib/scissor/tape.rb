require 'open-uri'
require 'tempfile'

module Scissor
  class Tape
    class Error < StandardError; end
    class EmptyFragment < Error; end
    class OutOfDuration < Error; end

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

    def self.new_from_url(url)
      file = nil
      content_types = {
        'audio/wav' => 'wav',
        'audio/x-wav' => 'wav',
        'audio/wave' => 'wav',
        'audio/x-pn-wav' => 'wav',
        'audio/mpeg' => 'mp3',
        'audio/x-mpeg' => 'mp3',
        'audio/mp3' => 'mp3',
        'audio/x-mp3' => 'mp3',
        'audio/mpeg3' => 'mp3',
        'audio/x-mpeg3' => 'mp3',
        'audio/mpg' => 'mp3',
        'audio/x-mpg' => 'mp3',
        'audio/x-mpegaudio' => 'mp3',
      }

      open(url) do |f|
        ext = content_types[f.content_type.downcase]

        file = Tempfile.new(['audio', '.' + ext])
        file.write(f.read)
        file.flush
      end

      new(file.path)
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
      @fragments.inject(0) do |memo, fragment|
        memo += fragment.duration
      end
    end

    def slice(start, length)
      if start + length > duration
        length = duration - start
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
      new_instance = Scissor()

      count.times do
        new_instance.add_fragments(orig_fragments)
      end

      new_instance
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
      if duration.zero?
        raise EmptyFragment
      end

      loop_count = (filled_duration / duration).to_i
      remain = filled_duration % duration

      loop(loop_count) + slice(0, remain)
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
            fragment.original_duration,
            !fragment.reversed?,
            fragment.pitch))
      end

      new_instance
    end

    def pitch(pitch, stretch = false)
      new_instance = self.class.new

      @fragments.each do |fragment|
        new_instance.add_fragment(Fragment.new(
            fragment.filename,
            fragment.start,
            fragment.original_duration,
            fragment.reversed?,
            fragment.pitch * (pitch.to_f / 100),
            stretch))
      end

      new_instance
    end

    def stretch(factor)
      factor_for_pitch = 1 / (factor.to_f / 100) * 100
      pitch(factor_for_pitch, true)
    end

    def to_file(filename, options = {})
      Scissor.mix([self], filename, options)
    end

    alias > to_file

    def >>(filename)
      to_file(filename, :overwrite => true)
    end

    def silence
      Scissor.silence(duration)
    end
  end
end
