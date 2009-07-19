require 'pathname'

module Scissor
  class Fragment
    attr_reader :filename, :start, :pitch

    def initialize(filename, start, duration, reverse = false, pitch = 100)
      @filename = Pathname.new(filename).realpath
      @start = start
      @duration = duration
      @reverse = reverse
      @pitch = pitch

      freeze
    end

    def duration
      @duration * (100 / pitch.to_f)
    end

    def true_duration
      @duration
    end

    def reversed?
      @reverse
    end

    def create(remaining_start, remaining_length)
      new_fragment = nil

      if remaining_start >= duration
        remaining_start -= duration
      else
        if remaining_start + remaining_length >= duration
          new_fragment = self.class.new(
            filename,
            start + remaining_start * pitch.to_f / 100,
            (duration - remaining_start) * pitch.to_f / 100,
            false,
            pitch)

          remaining_length -= duration - remaining_start
          remaining_start = 0
        else
          new_fragment = self.class.new(
            filename,
            start + remaining_start * pitch.to_f / 100,
            remaining_length * pitch.to_f / 100,
            false,
            pitch)

          remaining_start = 0
          remaining_length = 0
        end
      end

      return new_fragment, remaining_start, remaining_length
    end
  end
end
