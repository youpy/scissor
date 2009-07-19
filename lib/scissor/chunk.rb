require 'digest/md5'
require 'pathname'

module Scissor
  class Chunk
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

      while !remain.zero? && filled_duration > new_instance.duration
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
      writer = Writer.new

      writer.add_fragments(@fragments)
      writer.to_file(filename, options)

      self.class.new(filename)
    end

    alias > to_file

    def >>(filename)
      to_file(filename, :overwrite => true)
    end
  end
end
